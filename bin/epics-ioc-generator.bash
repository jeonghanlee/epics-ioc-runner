#!/usr/bin/env bash
#
# Systemd generator for EPICS IOCs managed by procServ.
# Generates transient unit files from simple configuration files.

set -e

declare -g NORMAL_DIR="$1"
declare -g CONF_DIR="/etc/procServ.d"
declare -g PROCSERV_EXEC="/usr/bin/procServ"

if [[ ! -d "${CONF_DIR}" ]] || [[ -z $(ls -A "${CONF_DIR}"/*.conf 2>/dev/null) ]]; then
    exit 0
fi

mkdir -p "${NORMAL_DIR}/multi-user.target.wants" || exit

for conf_file in "${CONF_DIR}"/*.conf; do

    awk -v target_dir="${NORMAL_DIR}" -v procserv="${PROCSERV_EXEC}" '
    BEGIN {
        FS="=";
    }

    NF >= 2 {
        key = $1;
        val = $0;
        sub(/^[^=]+=[ \t]*"?/, "", val);
        sub(/"?[ \t]*$/, "", val);
        config[key] = val;
    }

    END {
        name = config["IOC_NAME"];
        if (name == "") exit 0;

        user = config["IOC_USER"] ? config["IOC_USER"] : "ioc-srv";
        group = config["IOC_GROUP"] ? config["IOC_GROUP"] : "ioc";
        chdir = config["IOC_CHDIR"];
        cmd = config["IOC_CMD"];
        port = config["IOC_PORT"];

        svc_file = target_dir "/procserv-" name ".service";

        print "[Unit]" > svc_file;
        print "Description=procServ for " name >> svc_file;
        print "After=network.target remote-fs.target" >> svc_file;
        if (chdir != "") {
            print "ConditionPathIsDirectory=" chdir >> svc_file;
        }
        print "" >> svc_file;

        print "[Service]" >> svc_file;
        print "Type=simple" >> svc_file;
        print "User=" user >> svc_file;
        print "Group=" group >> svc_file;
        if (chdir != "") {
            print "WorkingDirectory=" chdir >> svc_file;
        }
        print "RuntimeDirectory=procserv/" name >> svc_file;

        print "ExecStart=" procserv " --foreground --logfile=- --name=" name " --ignore=^D^C^] --logoutcmd=^D --port=" port " " cmd >> svc_file;

        print "StandardOutput=syslog" >> svc_file;
        print "StandardError=inherit" >> svc_file;
        print "SyslogIdentifier=procserv-" name >> svc_file;

        symlink = target_dir "/multi-user.target.wants/procserv-" name ".service";
        system("ln -sf " svc_file " " symlink);
    }' "${conf_file}"

done
