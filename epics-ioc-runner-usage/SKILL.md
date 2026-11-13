---
name: epics-ioc-runner-usage
description: Explain and operate epics-ioc-runner, the Bash and systemd manager for EPICS IOCs running under procServ. Use when asked to read this repository, install or run ioc-runner, deploy, start, stop, attach to, monitor, list, or remove an IOC in system, local, or container mode, or to answer questions about its commands, configuration files, logs, and permission model. Applies to requests in any language.
---

# EPICS IOC Runner Usage

This repository provides `ioc-runner`, a Bash command that deploys and controls
EPICS IOCs running under `procServ`, using `systemd`, `bash`, and `sudo`. This
file is self-contained for orientation; the documents under `docs/` are the
source of detail.

In the commands below, `REPO` is the repository root: the directory that
contains the `epics-ioc-runner-usage/` directory holding this file. Derive it
from the absolute path of this file:

```bash
REPO="$(cd "$(dirname "<skill_file>")/.." && pwd)"
```

Replace `<skill_file>` with the absolute path of this file. Shell variables do
not persist between commands in most agent tools: set `REPO` in the same
command line that uses it.

## Use This Skill

An agent reads this file in one of two ways: its runtime loads it as a skill
when a request matches the description, or the user points to its path and the
agent reads it directly. Either way, follow this order:

1. Set `REPO` from the absolute path of this file.
2. For a question, go to Answer Questions: read the named document or run the
   named command, then answer with the source quoted.
3. For an operation, go to Choose The Mode, then Check The Installation, then
   Deploy And Run An IOC. Run read-only checks first (`--help`, `-V`, `list`,
   `status`, `view`, `log`).
4. Report each command run and its result. When a command fails, report its
   output; do not retry with a different mode or with `sudo`.

Use the Rules section as the stop conditions: anything it forbids needs the
user's explicit approval for that command.

## Choose The Mode

| Mode | Flag | Runs as | Typical use |
| --- | --- | --- | --- |
| System | none | `ioc-srv` service account, via `systemd` | Production hosts; needs the administrator setup and `ioc` group membership |
| Local | `--local` (alias `--user`) | Your own user, via `systemctl --user` | Testing without `root` or `sudo` |
| Container | `--container` | `root`, via `s6` supervision | Systemd-less container images; IOC output goes to container stdout |

When the user names no mode, ask which one applies. Do not choose system mode
on the user's behalf.

## Check The Installation

1. `command -v ioc-runner procServ con` prints the installed tools.
   `ioc-runner -V` prints the runner version, Git commit, commit date, and
   install date.
2. A checkout can run without installation: `"$REPO/bin/ioc-runner" -V` prints
   `install date: live`.
3. `procServ` is required. `con` is preferred for console access; `socat` is
   the fallback. `nc` is not supported.

Installation targets, run from `REPO` by the user: `make install.user` (CLI
under `~/.local/bin`, no root), `make install` (system-wide CLI only),
`make setup` (system-wide accounts, group, sudoers, systemd template, CLI).
`make help` lists all targets. The system targets invoke `sudo`: never run
them without the user's explicit approval. The full procedure is
`docs/INSTALL.md`.

## Deploy And Run An IOC

Run from the IOC's boot directory (`iocBoot/<ioc_boot_dir>`). Add `--local` or
`--container` for those modes; system mode uses no flag. When `ioc-runner` is
not installed, run `"$REPO/bin/ioc-runner"` in its place.

```bash
ioc-runner generate .
ioc-runner install .
ioc-runner start <ioc_boot_dir>
ioc-runner status <ioc_boot_dir>
```

- `generate` writes `<ioc_boot_dir>.conf`; `install` accepts the directory or
  the `.conf` file and asks before overwriting (`-f` answers yes).
- `start` reports whether the IOC reached `All initialization complete`.
- In system mode the IOC directory lives under `/opt/epics-iocs`, and
  `IOC_CHDIR` must be writable by `ioc-srv`; see `docs/USER_GUIDE.md`.
- `install` does not enable boot start; `enable` and `disable` do. Local
  boot start also needs `loginctl enable-linger`.

Operate and observe:

```bash
ioc-runner list -v
ioc-runner attach <ioc_name>
ioc-runner monitor <ioc_name>
ioc-runner log <ioc_name>
ioc-runner stop <ioc_name>
ioc-runner restart <ioc_name>
ioc-runner remove <ioc_name>
```

- `attach` is read/write; `monitor` is read-only. `Ctrl-A` detaches by
  default; `attach --detach-key <key>` selects another key.
- `log` prints the last 40 lines; `-n <count>` sets the count, `-f` follows.
- `view` prints the installed configuration and the rendered unit.
- `inspect` traces client PIDs on the IOC socket. System mode:
  `sudo ioc-runner inspect <ioc_name>`. Local mode: `ioc-runner --local inspect
  <ioc_name>`, without `sudo`, which would address the wrong user session.
  Container mode: `ioc-runner --container inspect <ioc_name>`.
- `remove` stops, disables, and deletes the installed configuration; the IOC
  directory stays in place.

## Configuration

A `.conf` file uses a bounded, single-line subset of systemd `EnvironmentFile`
syntax. Prefer `generate` over a hand-written file. The accepted syntax,
rejected forms, and the optional site-wide `site.env` layer are in
`docs/USER_GUIDE.md` and `docs/NETWORK_ENV.md`. Path and tool overrides
(`IOC_RUNNER_*` variables) are in `docs/USER_GUIDE_LOCAL.md`.

## Answer Questions

Answer from the repository, not from memory. Quote the file or command that
produced the answer.

- Commands and options: `"$REPO/bin/ioc-runner" --help`, then
  `docs/CLI_REFERENCE.md` for checks and exit status.
- Installation and administrator setup: `docs/INSTALL.md`, `docs/UNINSTALL.md`.
- Operator procedures: `docs/USER_GUIDE.md` (system mode),
  `docs/USER_GUIDE_LOCAL.md` (local mode).
- Security model, accounts, sudoers, setgid: `docs/ARCHITECTURE.md`,
  `docs/PERMISSION_MODEL.md`, and `policy/`.
- Log paths and rotation: `docs/LOG_LAYOUT.md`.
- Network environment variables: `docs/NETWORK_ENV.md`.
- Exit signals and restart behavior: `docs/EXIT_SIGNAL_HANDLING.md`,
  `docs/adr/`.
- Common questions and terms: `docs/FAQ.md`, `docs/GLOSSARY.md`.
- Release history: `CHANGELOG.md`.

## Rules

- Treat the repository as read-only unless the user asks for a change.
- Never run `make setup`, `make install`, `bin/setup-system-infra.bash`, or any
  `sudo` command without the user's explicit approval for that command.
- Do not guess a command, option, path, or version; read it from the
  repository and quote the source.
- Run test IOCs in local mode from a directory outside `REPO`.
