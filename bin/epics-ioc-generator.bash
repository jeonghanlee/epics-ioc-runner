#!/usr/bin/env bash
#
# Systemd generator for EPICS IOCs managed by procServ.
# Generates transient unit files from simple configuration files.

set -e

declare -g NORMAL_DIR="$1"
declare -g CONF_DIR="${CONF_DIR:-/etc/procServ.d}"
declare -g PROCSERV_EXEC=""

if [[ -x "/usr/local/bin/procServ" ]]; then
    PROCSERV_EXEC="/usr/local/bin/procServ"
elif [[ -x "/usr/bin/procServ" ]]; then
    PROCSERV_EXEC="/usr/bin/procServ"
else
	printf "%s\n" "Error: procServ executable not found in /usr/local/bin or /usr/bin." >&2
    printf "%s\n" "Please install procServ before managing EPICS IOCs." >&2
    exit 1
fi

if [[ ! -d "${CONF_DIR}" ]] || [[ -z $(ls -A "${CONF_DIR}"/*.conf 2>/dev/null) ]]; then
    exit 0
fi

for conf_file in "${CONF_DIR}"/*.conf; do

    awk -v target_dir="${NORMAL_DIR}" -v procserv="${PROCSERV_EXEC}" -v exec_mode="${EXEC_MODE:-system}" '
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

        svc_file = target_dir "/epics-" name ".service";

        printf "[Unit]\n" > svc_file;
        printf "Description=procServ for %s\n", name >> svc_file;
        printf "After=network.target remote-fs.target\n" >> svc_file;
        if (chdir != "") {
            printf "ConditionPathIsDirectory=%s\n", chdir >> svc_file;
        }
        printf "\n" >> svc_file;

        printf "[Service]\n" >> svc_file;
        printf "Type=simple\n" >> svc_file;

        if (exec_mode == "system") {
            printf "User=%s\n", user >> svc_file;
            printf "Group=%s\n", group >> svc_file;
        }

        if (chdir != "") {
            printf "WorkingDirectory=%s\n", chdir >> svc_file;
        }

        printf "RuntimeDirectory=procserv/%s\n", name >> svc_file;

        printf "ExecStart=%s --foreground --logfile=- --name=%s --ignore=^D^C^] --port=%s %s\n", \
                procserv, name, port, cmd >> svc_file;
        
        printf "StandardOutput=syslog\n" >> svc_file;
        printf "StandardError=inherit\n" >> svc_file;
        printf "SyslogIdentifier=epics-%s\n", name >> svc_file;

        printf "\n" >> svc_file;
        printf "[Install]\n" >> svc_file;
        if (exec_mode == "system") {
            printf "WantedBy=multi-user.target\n" >> svc_file;
        } else {
            printf "WantedBy=default.target\n" >> svc_file;
        }
    }' "${conf_file}"

done
