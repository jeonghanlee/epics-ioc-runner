#!/usr/bin/env bash
#
# Bash completion for ioc-runner.
# Provides context-aware suggestions for commands, options, and IOC targets.

_ioc_runner_completions() {
    local cur prev opts commands ioc_names conf_dir has_local cmd_found word

    # Initialize completion variables
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Define available command set and global options
    commands="generate install remove start stop restart status enable disable view list attach monitor inspect"
    opts="--local -f --force -v -vv -V --version -h --help"

    # Check for the presence of --local flag to determine target configuration path
    has_local=0
    for word in "${COMP_WORDS[@]}"; do
        if [[ "${word}" == "--local" ]]; then
            has_local=1
            break
        fi
    done

    # Resolve configuration directory based on the execution mode
    if [[ ${has_local} -eq 1 ]]; then
        conf_dir="${HOME}/.config/procServ.d"
    else
        conf_dir="/etc/procServ.d"
    fi

    # Handle global options starting with a dash
    if [[ "${cur}" == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi

    # Identify the primary command action in the current command line
    cmd_found=""
    for word in "${COMP_WORDS[@]}"; do
        if [[ " ${commands} " =~ " ${word} " ]]; then
            cmd_found="${word}"
            break
        fi
    done

    # Suggest commands or global options if no primary action is identified
    if [[ -z "${cmd_found}" ]]; then
        COMPREPLY=( $(compgen -W "${commands} ${opts}" -- "${cur}") )
        return 0
    fi

    # Generate context-specific completions based on the identified command
    case "${cmd_found}" in
        start|stop|restart|status|enable|disable|view|remove|attach|monitor|inspect)
            # Fetch valid IOC names by parsing .conf files in the resolved directory
            if [[ -d "${conf_dir}" ]]; then
                ioc_names=$(find "${conf_dir}" -maxdepth 1 -name "*.conf" -exec basename {} .conf \; 2>/dev/null)
            else
                ioc_names=""
            fi
            COMPREPLY=( $(compgen -W "${ioc_names}" -- "${cur}") )
            ;;
        install|generate)
            # Enable standard file and directory path completion
            COMPREPLY=( $(compgen -f -d -- "${cur}") )
            ;;
        list)
            # Suggest verbosity flags specific to the list action
            COMPREPLY=( $(compgen -W "-v -vv" -- "${cur}") )
            ;;
        *)
            COMPREPLY=()
            ;;
    esac

    return 0
}

# Register the completion handler for the ioc-runner binary
complete -F _ioc_runner_completions ioc-runner
