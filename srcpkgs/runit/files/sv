# bash completion for runit sv(1)

_sv()
{
    local cur prev words cword commands
    _init_completion || return

    commands='up down status once pause cont hup alarm interrupt 1 2 term kill exit start stop restart shutdown force-stop force-reload force-restart force-shutdown'

    case $prev in
        -w)
            return
            ;;
        -* | sv)
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return
            ;;
        *)
            COMPREPLY=( /var/service/* )
            COMPREPLY=( ${COMPREPLY[@]##*/} )
            COMPREPLY=( $(compgen -W '${COMPREPLY[@]}' -- ${cur}) )
            return
            ;;
    esac
}
complete -F _sv sv
