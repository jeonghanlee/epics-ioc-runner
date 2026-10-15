"""Exercise the shipped CLI with native systemd, procServ and softIoc.

Only task-owned instances, systemd drop-ins and a network namespace change.
No command output, kernel table, product function or supervisor is replaced.
"""
import grp
import hashlib
import json
import os
from pathlib import Path
import pwd
import re
import shlex
import shutil
import signal
import stat
import subprocess
import sys
import threading
import time


SYSTEM_PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UNAVAILABLE = ("[not set]", "18446744073709551615")
HOLD_SECONDS = 30
POLL_SECONDS = 10
DISCONNECT_ATTEMPTS = 20


class NativeList:
    def __init__(self, arguments):
        self.scope, self.user, self.origin, root, work, base, arch = arguments[:7]
        self.catalog = ["{}.{}".format(*row.split("|")[:2]) for row in arguments[7:]]
        self.recorded = set()
        self.root, self.work = Path(root).resolve(), Path(work).resolve()
        self.softioc = Path(base) / "bin" / arch / "softIoc"
        self.runner = (self.root / "bin/ioc-runner" if self.origin == "source"
                       else Path("/usr/local/bin/ioc-runner"))
        self.name = "ListStates{}".format(self.work.name.rsplit(".", 1)[1])
        self.unit = "epics-@{}.service".format(self.name)
        self.blocker = "ioc-list-block-{}.service".format(self.name)
        self.env = dict(PATH=SYSTEM_PATH, LANG="C", LC_ALL="C",
                        SYSTEMD_COLORS="0", SYSTEMD_PAGER="cat",
                        EPICS_BASE=base, EPICS_HOST_ARCH=arch,
                        EPICS_IOCSH_HISTFILE="")
        self.prefix = []
        self.namespace = None
        self.client = None
        self.clients = []
        self.stopped = None
        self.started = False
        self.calls = 0
        self.failures = 0
        self.protected = {}
        self.created = []
        self.created_inodes = {}
        self.dropdir_created = False
        self.owned_pids = {}
        self.disconn = False
        self.disconn_cli = False
        self.preflight_failure = "P00.root"
        (self.work / "invocation.json").write_text(json.dumps(dict(
            scope=self.scope, user=self.user, runner=str(self.runner),
            unit=self.unit, blocker=self.blocker), indent=2) + "\n")

    def event(self, key, ok=None, reason="", state=None):
        if key not in self.catalog or key in self.recorded:
            raise RuntimeError("invalid or duplicate check: " + key)
        self.recorded.add(key)
        state = state or ("PASS" if ok else "FAIL")
        if state == "FAIL":
            self.failures += 1
        reason = reason.replace("\n", " ").replace("\r", " ").replace("\t", " ") or "condition not observed"
        print("list-states.{}\t{}\t{}".format(key, state, "-" if state == "PASS" else reason), flush=True)

    def run(self, argv, ns=False, principal=True, required=True, timeout=40):
        self.calls += 1
        argv = [str(item) for item in argv]
        command = (self.prefix if principal else []) + argv
        if ns:
            command = ["/usr/bin/nsenter", "-t", str(self.namespace.pid), "-n", "--"] + command
        process = subprocess.Popen(command, env=self.env, stdin=subprocess.DEVNULL,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   universal_newlines=True, start_new_session=True)
        error = None
        try:
            stdout, stderr = process.communicate(timeout=timeout)
        except BaseException as caught:
            # The unreaped session leader reserves this process-group ID.
            os.killpg(process.pid, signal.SIGKILL)
            stdout, stderr = process.communicate()
            error = caught
        result = subprocess.CompletedProcess(command, process.returncode, stdout, stderr)
        record = dict(argv=command, exit=result.returncode, stdout=result.stdout,
                      stderr=result.stderr, monotonic=time.monotonic(),
                      interrupted=str(error) if error else None)
        (self.work / "call-{:04d}.json".format(self.calls)).write_text(json.dumps(record, indent=2) + "\n")
        if error:
            raise error
        if required and result.returncode:
            raise RuntimeError("command {} exited {}: {}".format(self.calls, result.returncode, result.stderr))
        return result

    def cli(self, *args, **kwargs):
        return self.run(["/bin/bash", "-p", self.runner] +
                        (["--local"] if self.scope == "local" else []) + list(args), **kwargs)

    def control(self, *args, **kwargs):
        return self.run(["/usr/bin/systemctl"] +
                        (["--user"] if self.scope == "local" else []) + list(args), **kwargs)

    def props(self):
        text = self.control("show", self.unit, "-p",
                            "MainPID,ActiveState,SubState,Job,CPUUsageNSec,MemoryCurrent").stdout
        return dict(line.split("=", 1) for line in text.splitlines() if "=" in line)

    def rows(self, ns=False):
        text = self.run(["/bin/cat", "/proc/net/unix"], ns=ns).stdout
        return [line.split() for line in text.splitlines()[1:]
                if len(line.split()) == 8 and line.split()[7] == str(self.socket)]

    def query(self, ns=False):
        out = self.cli("list", "-vv", ns=ns).stdout
        rows = [[cell.strip() for cell in line.split("|")] for line in out.splitlines() if "|" in line]
        rows = [row for row in rows if row[0] == self.name]
        if len(rows) != 1 or len(rows[0]) != 13:
            raise RuntimeError("expected exactly one 13-column row for {}".format(self.name))
        if rows[0][9] == "DISCONN":
            self.disconn_cli = True
        return rows[0]

    def wait(self, predicate, seconds=POLL_SECONDS):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if predicate():
                return True
            time.sleep(0.1)
        return False

    @staticmethod
    def identity(pid):
        proc = Path("/proc") / str(pid)
        tail = (proc / "stat").read_text().rsplit(") ", 1)[1].split()
        return (str(pid), tail[19], os.readlink(str(proc / "exe")))

    def remember(self, pid):
        identity = self.identity(pid)
        self.owned_pids[str(pid)] = identity
        (self.work / "owned-pids.json").write_text(json.dumps(self.owned_pids, indent=2) + "\n")
        return identity

    def signal_owned(self, identity, sig):
        try:
            if self.identity(identity[0]) != identity:
                raise RuntimeError("PID identity changed")
            os.kill(int(identity[0]), sig)
        except FileNotFoundError:
            return

    @staticmethod
    def fingerprint(path):
        if not path.exists():
            return None
        s = path.lstat()
        if not stat.S_ISREG(s.st_mode):
            raise RuntimeError("protected file is not regular: " + str(path))
        return (s.st_uid, s.st_gid, stat.S_IMODE(s.st_mode), s.st_ino,
                s.st_mtime_ns,
                hashlib.sha256(path.read_bytes()).hexdigest())

    def create(self, path, content, mode=0o644):
        # Pin the parent directory and reject substituted symbolic links.
        parent = self.open_directory(path.parent)
        try:
            fd = os.open(path.name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                         mode, dir_fd=parent)
            self.created.append(path)
            with os.fdopen(fd, "w") as stream:
                metadata = os.fstat(stream.fileno())
                self.created_inodes[path] = (metadata.st_dev, metadata.st_ino)
                os.fchmod(stream.fileno(), mode)
                stream.write(content)
        finally:
            os.close(parent)

    def remove_created(self, path):
        parent = self.open_directory(path.parent)
        try:
            metadata = os.stat(path.name, dir_fd=parent, follow_symlinks=False)
            if (metadata.st_dev, metadata.st_ino) != self.created_inodes[path]:
                raise RuntimeError("owned file was replaced: " + str(path))
            os.unlink(path.name, dir_fd=parent)
            self.created.remove(path)
        finally:
            os.close(parent)

    def open_directory(self, path):
        fd = os.open("/", os.O_RDONLY | os.O_DIRECTORY)
        try:
            for part in path.parts[1:]:
                child = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
                os.close(fd)
                fd = child
                metadata = os.fstat(fd)
                trusted = metadata.st_uid in (0, self.uid)
                writable = stat.S_IMODE(metadata.st_mode) & 0o022
                sticky_root = metadata.st_uid == 0 and metadata.st_mode & stat.S_ISVTX
                if not trusted or (writable and not sticky_root):
                    raise RuntimeError("unsafe directory: " + str(path))
            return fd
        except BaseException:
            os.close(fd)
            raise

    @staticmethod
    def stop_process(process):
        if process and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)

    def preflight(self):
        self.event("P00.root", os.geteuid() == 0, "root is required for network namespace isolation")
        if os.geteuid() != 0:
            return False
        self.preflight_failure = "P00.tools"
        required = ["systemctl", "busctl", "strace", "socat", "unshare", "nsenter", "setpriv", "pgrep"]
        missing = [name for name in required if not os.access("/usr/bin/" + name, os.X_OK)]
        if shutil.which("ss", path=SYSTEM_PATH) is None:
            missing.append("ss")
        self.event("P00.tools", not missing, "missing tools: " + ",".join(missing))
        if missing:
            return False
        self.preflight_failure = "P00.prepared-host"
        principal = pwd.getpwnam(self.user)
        if self.scope == "local" and principal.pw_uid == 0:
            raise RuntimeError("local-user must name a non-root account")
        self.env.update(HOME=principal.pw_dir, USER=self.user, LOGNAME=self.user)
        self.prefix = ["/usr/bin/setpriv", "--reuid", str(principal.pw_uid),
                       "--regid", str(principal.pw_gid), "--init-groups"]
        if self.scope == "local":
            self.env.update(XDG_RUNTIME_DIR="/run/user/{}".format(principal.pw_uid),
                            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/{}/bus".format(principal.pw_uid))
            self.confdir = Path(principal.pw_dir) / ".config/procServ.d"
            self.unitdir = Path(principal.pw_dir) / ".config/systemd/user"
            self.rundir = Path(self.env["XDG_RUNTIME_DIR"]) / "procserv"
            runtime = principal
        else:
            self.confdir, self.unitdir, self.rundir = map(Path, ["/etc/procServ.d", "/etc/systemd/system", "/run/procserv"])
            runtime = pwd.getpwnam("ioc-srv")
        self.uid, self.gid = principal.pw_uid, principal.pw_gid
        self.runtime_uid = runtime.pw_uid
        self.runtime_gid = principal.pw_gid if self.scope == "local" else grp.getgrnam("ioc").gr_gid
        self.socket = self.rundir / self.name / "control"
        self.config = self.confdir / (self.name + ".conf")
        self.dropdir = self.unitdir / (self.unit + ".d")
        self.blockpath = self.unitdir / self.blocker
        template = self.unitdir / "epics-@.service"
        shared = [template, self.runner, Path("/etc/passwd"), Path("/etc/group"),
                  self.unitdir / "epics-logrotate.service", self.unitdir / "epics-logrotate.timer"]
        if self.scope == "local":
            shared.append(self.confdir.parent / "ioc-runner/logrotate.conf")
        safe_env = all(re.fullmatch(r"/[A-Za-z0-9_./+-]+", value) for value in
                       [str(self.softioc), str(self.work), principal.pw_dir])
        if (not safe_env or not self.softioc.is_absolute() or
                not all(p.exists() for p in [self.runner, self.softioc, self.confdir, self.unitdir, template])):
            self.event("P00.prepared-host", False, "runner, native softIoc or existing IOC infrastructure missing")
            return False
        if os.statvfs(str(self.work)).f_flag & os.ST_NOEXEC:
            self.event("P00.prepared-host", False, "the test workspace must allow native IOC execution")
            return False
        for directory in [self.work, self.unitdir]:
            os.close(self.open_directory(directory))
        self.protected = {str(p): self.fingerprint(p) for p in shared}
        if any(os.path.lexists(str(p)) for p in [self.config, self.dropdir, self.blockpath, self.socket.parent]):
            raise RuntimeError("task paths already exist")
        self.control("show", self.unit, "-p", "LoadState")
        if self.scope == "local":
            if not all(path.is_file() for path in shared):
                raise RuntimeError("local template and log rotation must already be installed")
            self.control("is-enabled", "--quiet", "epics-logrotate.timer")
            self.control("is-active", "--quiet", "epics-logrotate.timer")
        self.cli("-V")
        self.run(["/usr/bin/strace", "-V"])
        self.run(["/usr/bin/strace", "-e", "trace=none", "-e",
                  "inject=listen:delay_enter=8000000:when=1", "/bin/true"])
        self.run(["/usr/bin/systemctl", "--version"])
        self.run(["/usr/bin/uname", "-r"])
        self.event("P00.prepared-host", True)
        self.preflight_failure = "P00.network-namespace"
        self.namespace = subprocess.Popen(["/usr/bin/unshare", "--net", "--", "/bin/sleep", "600"],
                                           env=self.env, stdin=subprocess.DEVNULL,
                                           stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        def namespace_ready():
            if self.namespace.poll() is not None:
                return True
            try:
                return os.readlink("/proc/{}/ns/net".format(self.namespace.pid)) != os.readlink("/proc/self/ns/net")
            except FileNotFoundError:
                return False

        ready = self.wait(namespace_ready)
        ready = ready and self.namespace.poll() is None
        self.event("P00.network-namespace", ready, "a private network namespace could not be created")
        if ready:
            self.remember(self.namespace.pid)
        else:
            self.stop_process(self.namespace)
            (self.work / "namespace.stderr").write_bytes(self.namespace.communicate()[1])
        return ready

    def setup(self):
        os.chmod(str(self.work), 0o755)
        self.payload = self.work / self.name
        self.payload.mkdir(mode=0o755)
        os.chmod(str(self.payload), 0o755)
        os.chown(str(self.payload), self.uid, self.gid)
        self.create(self.payload / "st.cmd", "#!{}\niocInit()\n".format(self.softioc), 0o755)
        os.chown(str(self.payload / "st.cmd"), self.uid, self.gid)
        if self.scope == "system":
            os.chown(str(self.payload), self.uid, self.runtime_gid)
            os.chmod(str(self.payload), 0o2775)
        self.cli("generate", str(self.payload))
        self.started = True
        self.cli("install", str(self.payload / (self.name + ".conf")))
        parent = self.open_directory(self.unitdir)
        try:
            os.mkdir(self.dropdir.name, mode=0o755, dir_fd=parent)
            self.dropdir_created = True
            directory = os.open(self.dropdir.name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent)
            try:
                if os.fstat(directory).st_uid != 0:
                    raise RuntimeError("task unit directory was replaced")
                os.fchmod(directory, 0o755)
            finally:
                os.close(directory)
        finally:
            os.close(parent)
        self.create(self.dropdir / "10-observation.conf",
                    "[Service]\nCPUAccounting=no\nMemoryAccounting=no\nRuntimeDirectoryPreserve=yes\nRestart=no\nKillSignal=SIGKILL\n")
        self.control("daemon-reload")
        self.cli("start", self.name)
        self.check_native()
        self.event("S01.native-ioc-started", True)

    def check_native(self):
        def ready():
            props = self.props()
            if props.get("ActiveState") != "active" or props.get("MainPID", "0") == "0":
                return False
            try:
                main = self.identity(int(props["MainPID"]))
                if Path(main[2]).name != "procServ":
                    return False
                result = self.run(["/usr/bin/pgrep", "-P", main[0]], required=False)
                if result.returncode not in (0, 1):
                    raise RuntimeError("native child lookup failed")
                matches = [pid for pid in result.stdout.split()
                           if os.path.realpath("/proc/{}/exe".format(pid)) == str(self.softioc.resolve())]
                if len(matches) != 1:
                    return False
                self.main = self.remember(int(main[0]))
                self.child = self.remember(int(matches[0]))
                return True
            except (FileNotFoundError, ProcessLookupError):
                return False

        if not self.wait(ready):
            raise RuntimeError("active native procServ with one softIoc child was not observed")

    def inactive(self):
        self.cli("stop", self.name)
        self.control("reset-failed", self.unit, required=False)
        if not self.socket.is_socket():
            raise RuntimeError("native stopped socket was not retained")
        self.create(self.blockpath, "[Service]\nType=oneshot\nExecStart=/bin/sleep 8\n")
        dependency = self.dropdir / "20-wait.conf"
        self.create(dependency, "[Unit]\nRequires={}\nAfter={}\n".format(self.blocker, self.blocker))
        self.control("daemon-reload")
        self.control("start", "--no-block", self.unit)
        ready = self.wait(lambda: self.props().get("ActiveState") == "inactive" and
                          self.props().get("Job", "0").split()[0] != "0", seconds=3)
        row = self.query()
        self.event("S02.inactive-job-visible", ready and row[1] == "inactive", "queued inactive IOC did not render inactive")
        if not self.wait(lambda: self.props()["ActiveState"] == "active", seconds=15):
            raise RuntimeError("queued IOC did not resume")
        self.remove_created(dependency)
        self.control("daemon-reload")
        self.check_native()

    def sentinels(self):
        bus = ["/usr/bin/busctl"] + (["--user"] if self.scope == "local" else [])
        obj = shlex.split(self.run(bus + ["call", "org.freedesktop.systemd1", "/org/freedesktop/systemd1",
                                         "org.freedesktop.systemd1.Manager", "GetUnit", "s", self.unit]).stdout)[1]
        raw = {}
        for prop in ("CPUUsageNSec", "MemoryCurrent"):
            raw[prop] = self.run(bus + ["get-property", "org.freedesktop.systemd1", obj,
                                       "org.freedesktop.systemd1.Service", prop]).stdout.strip()
        props, row = self.props(), self.query()
        self.event("S03.dbus-unavailable-values", all(v == "t 18446744073709551615" for v in raw.values()),
                   "native D-Bus properties did not both report UINT64_MAX")
        self.event("S03.unavailable-values-render-na",
                   all(props[p] in UNAVAILABLE for p in raw) and row[4:6] == ["N/A", "N/A"],
                   "unavailable native values did not render N/A")
        numeric = all(props[p] == UNAVAILABLE[1] for p in raw)
        self.event("S03.numeric-sentinel-input", state="PASS" if numeric else "SKIP",
                   reason="systemctl did not supply both raw numeric sentinels: " +
                   json.dumps({prop: props.get(prop) for prop in raw}, sort_keys=True))
        self.event("S03.numeric-sentinel-render-na", state=("PASS" if row[4:6] == ["N/A", "N/A"] else "FAIL") if numeric else "SKIP",
                   reason="requires list-states.S03.numeric-sentinel-input; numeric fallback remains unverified")

    def unconnected(self):
        self.cli("stop", self.name)
        template = (self.unitdir / "epics-@.service").read_text().replace("\\\n", "")
        lines = [line[len("ExecStart="):] for line in template.splitlines() if line.startswith("ExecStart=")]
        if len(lines) != 1 or not lines[0].startswith("/"):
            raise RuntimeError("one absolute native template ExecStart is required")
        trace = self.work / "listen-trace"
        trace.mkdir(mode=0o700)
        os.chown(str(trace), self.runtime_uid, self.runtime_gid)
        timing = self.dropdir / "30-listen-delay.conf"
        self.create(timing, "[Service]\nExecStart=\nExecStart=/usr/bin/strace -D -f -o {}/native -e trace=network -e inject=listen:delay_enter=8000000:when=1 {}\n".format(trace, lines[0]))
        self.control("daemon-reload")
        # The existing generated service is instrumented only for syscall timing.
        # This case verifies list, and does not claim CLI start-path coverage.
        self.control("start", "--no-block", self.unit)
        ready = self.wait(lambda: any(r[5] == "01" and int(r[3], 16) == 0 for r in self.rows()), seconds=5)
        self.event("S04.bound-before-listen", ready, "native bound socket was not observed before listen")
        row = self.query()
        self.event("S04.unconnected-rendered", ready and row[9] == "UNCONN", "list did not render UNCONN")
        if not self.wait(lambda: any(int(r[3], 16) & 0x10000 for r in self.rows()), seconds=15):
            raise RuntimeError("delayed listen did not complete")
        self.control("stop", self.unit)
        self.remove_created(timing)
        self.control("daemon-reload")
        self.cli("start", self.name)
        self.check_native()

    def connect_client(self, ns, label):
        log = (self.work / (label + ".stdout")).open("w")
        error = (self.work / (label + ".stderr")).open("w")
        prefix = ["/usr/bin/nsenter", "-t", str(self.namespace.pid), "-n", "--"] if ns else []
        self.client = subprocess.Popen(prefix + self.prefix +
                                       ["/usr/bin/socat", "-u", "UNIX-CONNECT:" + str(self.socket), "STDOUT"],
                                       env=self.env, stdin=subprocess.DEVNULL, stdout=log, stderr=error)
        self.clients.append(self.client)
        log.close()
        error.close()

    def close_client(self):
        self.stop_process(self.client)

    def connections(self):
        original = (self.main, self.child)
        self.connect_client(False, "same-namespace-client")
        ready = self.wait(lambda: any(r[5] == "03" for r in self.rows()))
        listeners = [r for r in self.rows() if int(r[3], 16) & 0x10000]
        host = self.query()
        self.event("S05.listener-priority", ready and len(listeners) == 1 and
                   host[9:11] == ["LISTEN", listeners[0][6]], "listener did not win over the accepted socket")
        self.close_client()
        if not self.wait(lambda: len(self.rows()) == 1):
            raise RuntimeError("same-namespace connection remained")
        self.signal_owned(self.main, signal.SIGSTOP)
        self.stopped = self.main
        self.connect_client(True, "separate-namespace-client")
        ready = self.wait(lambda: any(r[5] == "02" for r in self.rows(ns=True)))
        row = self.query(ns=True)
        self.event("S05.connecting-rendered", ready and row[9] == "CONNECTING", "pending native connection did not render CONNECTING")
        self.signal_owned(self.main, signal.SIGCONT)
        self.stopped = None
        ready = self.wait(lambda: any(r[5] == "03" for r in self.rows(ns=True)))
        accepted = [r for r in self.rows(ns=True) if r[5] == "03"]
        row = self.query(ns=True)
        self.event("S05.established-rendered", ready and len(accepted) == 1 and
                   row[9:11] == ["ESTAB", accepted[0][6]] and row[10] != "0",
                   "accepted native connection did not render ESTAB with its inode")
        first_client = self.client
        first_inode = row[10]
        self.connect_client(True, "second-namespace-client")

        def established_pair():
            rows = self.rows(ns=True)
            return (len(rows) == 2 and len({r[6] for r in rows}) == 2 and
                    all(r[5] == "03" and not int(r[3], 16) & 0x10000 for r in rows))

        ready = self.wait(established_pair)
        before = self.rows(ns=True)
        before_call = self.calls
        selected = self.query(ns=True)
        selected_call = self.calls
        after = self.rows(ns=True)
        after_call = self.calls
        before_keys = [(r[3], r[5], r[6], r[7]) for r in before]
        after_keys = [(r[3], r[5], r[6], r[7]) for r in after]
        valid_input = (ready and len(before) == len(after) == 2 and
                       len({r[6] for r in before}) == 2 and before_keys == after_keys and
                       all(r[5] == "03" and not int(r[3], 16) & 0x10000 for r in before))
        correct_selection = valid_input and selected[9:11] == ["ESTAB", before[0][6]]
        selection = dict(before=before, after=after, observed=selected,
                         before_call=before_call, cli_call=selected_call, after_call=after_call,
                         client_pids=[first_client.pid, self.client.pid], passed=correct_selection)
        (self.work / "nonlistener-selection.json").write_text(json.dumps(selection, indent=2) + "\n")
        self.event("S05.first-nonlistener-selected", correct_selection,
                   "two stable non-listening rows did not select the first inode")
        if not valid_input:
            raise RuntimeError("two stable native non-listening rows are required for the hold")
        self.check_native()
        self.event("S05.native-processes-preserved", original == (self.main, self.child), "procServ or softIoc identity changed")
        observations = []
        deadline = None
        while True:
            started = time.monotonic()
            row = self.query(ns=True)
            completed = time.monotonic()
            observations.append(dict(call=self.calls, started=started, completed=completed,
                                     row=row, clients_alive=first_client.poll() is None and
                                     self.client.poll() is None))
            if deadline is None:
                deadline = completed + HOLD_SECONDS
            if started >= deadline:
                break
            time.sleep(min(1, max(0, deadline - time.monotonic())))
        separation = observations[-1]["started"] - observations[0]["completed"]
        stable = all(sample["row"][9:11] == ["ESTAB", before[0][6]] and
                     sample["row"][12] == str(self.socket) and sample["clients_alive"]
                     for sample in observations)
        hold = dict(seconds=separation, samples=len(observations), stable=stable,
                    timing_basis="last query start minus first query completion",
                    observations=observations)
        (self.work / "hold.json").write_text(json.dumps(hold, indent=2) + "\n")
        self.event("S06.established-held-thirty-seconds", stable and separation >= HOLD_SECONDS,
                   "same-inode ESTAB observations were not separated by thirty seconds")
        self.close_client()
        self.client = first_client
        if not self.wait(lambda: [r[6] for r in self.rows(ns=True)] == [first_inode]):
            raise RuntimeError("second connection remained or the first connection disappeared")

    def disconnect(self):
        self.close_client()
        # Bounded native teardown observation; absence of state 04 is not a pass
        # for the DISCONN branch and is not a proof that it is unreachable.
        for attempt in range(DISCONNECT_ATTEMPTS):
            self.connect_client(True, "teardown-{:02d}".format(attempt))
            if not self.wait(lambda: any(r[5] == "03" for r in self.rows(ns=True))):
                raise RuntimeError("native teardown connection did not establish")
            closer = threading.Timer(0.01 * (attempt % 5 + 1), self.client.terminate)
            closer.start()
            try:
                before = self.rows(ns=True)
                self.query(ns=True)
                after = self.rows(ns=True)
                self.disconn = any(r[5] == "04" for r in before + after) or self.disconn
            finally:
                closer.join(timeout=5)
                self.close_client()
            if not self.wait(lambda: not self.rows(ns=True)):
                raise RuntimeError("native teardown connection remained")
        # A native CLI DISCONN observation also establishes that its real input
        # was present, even when the adjacent independent snapshots missed it.
        self.event("S07.disconnecting-input-observed", state="PASS" if self.disconn or self.disconn_cli else "SKIP",
                   reason="no matching native state 04 in twenty teardown samples; reachability remains open")
        self.event("S07.disconnecting-rendered", state="PASS" if self.disconn_cli else "SKIP",
                   reason="no native CLI DISCONN observation; no substituted kernel input was used")
        self.event("S07.closed-connection-unknown", self.query(ns=True)[9:11] == ["UNKNOWN", "N/A"],
                   "closed namespace connection did not render UNKNOWN and N/A")

    def cleanup(self):
        errors = []
        if self.stopped:
            try:
                self.signal_owned(self.stopped, signal.SIGCONT)
            except Exception as error:
                errors.append(str(error))
        for process in list(reversed(self.clients)) + [self.namespace]:
            try:
                self.stop_process(process)
            except Exception as error:
                errors.append(str(error))
        if self.started:
            for command in [("stop", self.unit), ("stop", self.blocker)]:
                try:
                    self.control(*command, required=False, timeout=20)
                except Exception as error:
                    errors.append(str(error))
            try:
                if os.path.lexists(str(self.config)):
                    self.cli("remove", self.name, timeout=20)
            except Exception as error:
                errors.append(str(error))
            for path in reversed(self.created[:]):
                if path.parent == self.dropdir or path == self.blockpath:
                    try:
                        self.remove_created(path)
                    except FileNotFoundError:
                        pass
                    except Exception as error:
                        errors.append(str(error))
            try:
                if self.dropdir_created:
                    parent = self.open_directory(self.unitdir)
                    try:
                        os.rmdir(self.dropdir.name, dir_fd=parent)
                    finally:
                        os.close(parent)
                self.control("daemon-reload")
                self.control("reset-failed", self.unit, self.blocker, required=False)
                for unit in (self.unit, self.blocker):
                    state = self.control("show", unit, "-p", "ActiveState", "-p", "MainPID",
                                         "-p", "ControlPID", required=False).stdout.splitlines()
                    if (not state or any(item in state for item in ["ActiveState=active", "ActiveState=activating",
                                                                   "ActiveState=deactivating"]) or
                            any(item.startswith(("MainPID=", "ControlPID=")) and item.split("=", 1)[1] != "0"
                                for item in state)):
                        errors.append("owned unit remains active: " + unit)
                if any(os.path.lexists(str(path)) for path in [self.config, self.socket.parent, self.blockpath]):
                    errors.append("owned configuration or runtime path remains")
                for pid, identity in self.owned_pids.items():
                    try:
                        if self.identity(pid) == identity:
                            errors.append("owned PID remains: " + pid)
                    except (FileNotFoundError, ProcessLookupError):
                        pass
            except Exception as error:
                errors.append(str(error))
            self.event("S08.owned-resources-cleaned", not errors, "; ".join(errors))
            equal = all(self.fingerprint(Path(p)) == before for p, before in self.protected.items())
            self.event("S08.shared-assets-preserved", equal, "a protected shared asset changed")
        (self.work / "cleanup.json").write_text(json.dumps(dict(errors=errors, protected=self.protected), indent=2) + "\n")
        return not errors


def main():
    test = NativeList(sys.argv[1:])
    status = 0
    preflight_ok = False
    def interrupted(number, _frame):
        raise RuntimeError("interrupted by signal {}".format(number))

    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        preflight_ok = test.preflight()
        if not preflight_ok:
            raise RuntimeError("required preflight failed")
        test.setup()
        test.inactive()
        test.sentinels()
        test.unconnected()
        test.connections()
        test.disconnect()
    except Exception as error:
        if not preflight_ok and test.preflight_failure not in test.recorded:
            test.event(test.preflight_failure, False, str(error))
        print("Native list test aborted: {}".format(error), file=sys.stderr)
        status = 1
    finally:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        try:
            if not test.cleanup():
                status = 1
        except Exception as error:
            print("Native list cleanup failed: {}".format(error), file=sys.stderr)
            status = 1
        if not preflight_ok:
            for key in test.catalog:
                if key not in test.recorded:
                    test.event(key, state="SKIP", reason="requires list-states." + test.preflight_failure)
    return 1 if status or test.failures else 0


if __name__ == "__main__":
    sys.exit(main())
