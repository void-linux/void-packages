# Source this file in BASH to get command completion (using tab) for
# boinc and boinccmd. Written by Frank S. Thomas <fst@debian.org>.
# See also: http://boinc.berkeley.edu/trac/wiki/BashCommandCompletion

_boinc()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="$(boinc_client --help | \
        sed -n -r 's/^[[:space:]]*(--[a-z_]*).*/\1/p')"

    # Handle options that require one or more arguments.
    case "$prev" in
        --attach_project|--detach_project|--reset_project|--update_prefs|\
        --gui_rpc_port)
            return 0
        ;;
    esac

    # Handle options that require two arguments.
    if [[ COMP_CWORD -gt 1 ]]; then
        pprev="${COMP_WORDS[COMP_CWORD-2]}"

        case "$pprev" in
            --attach_project)
                return 0
            ;;
        esac
    fi

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return 0
    fi
}
complete -F _boinc -o default boinc_client

_boinccmd()
{
    local cur prev opts cmds
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="--host --passwd -h --help -V --version"
    cmds="$(boinc_cmd --help 2>&1 | \
        sed -n -r 's/^[[:space:]]*(--[a-z_]*).*/\1/p')"

    # The following construct assures that:
    # - no command follows if one of $opts or $cmds was given
    # - after --host follows only one command or --passwd and one command
    # - after --passwd follows only one command
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$opts $cmds" -- "$cur") )
        return 0
    else
        if [[ "${COMP_WORDS[@]}" =~ ".* --host .* --passwd .*" ]]; then
            if [[ $COMP_CWORD -eq 5 ]]; then
                COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
            fi
        elif [[ "${COMP_WORDS[@]}" =~ ".* --passwd .*" ]]; then
            if [[ $COMP_CWORD -eq 3 ]]; then
                COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
            fi
        elif [[ "${COMP_WORDS[@]}" =~ ".* --host .*" ]]; then
            if [[ $COMP_CWORD -eq 3 ]]; then
                COMPREPLY=( $(compgen -W "--passwd $cmds" -- "$cur") )
            fi
       fi
    fi

    # Handle options/commands that require one or more arguments.
    case "$prev" in
        --get_messages|--passwd)
            return 0
        ;;

        --host)
            _known_hosts
            return 0
        ;;

        --set_run_mode|--set_network_mode)
            COMPREPLY=( $(compgen -W "always auto never" -- "$cur") )
            return 0
        ;;

        --set_screensaver_mode)
            COMPREPLY=( $(compgen -W "on off" -- "$cur") )
            return 0
        ;;
    esac
}
complete -F _boinccmd boinc_cmd

# vim: syntax=sh