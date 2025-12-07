_x_install() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    local options

    if [[ "$prev" == "-m" ]]; then
        return 0

    elif [[ "$prev" == "-l" ]]; then
        local current_date=$(date +%Y-%m-%d)
        COMPREPLY=( $(compgen -W "$current_date" -- "$cur") )

    else
        options=$(xbps-query -Rs "$cur" 2>/dev/null | awk '{print $2}' | sed -E 's/-[0-9].*$//' | sort -u)
        COMPREPLY=( $(compgen -W "$options" -- "$cur") )
    fi
}

complete -F _x_install xr

