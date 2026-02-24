# vim: set ts=4 sw=4 et:
#
# This hook performs the following task:
# - Identifies any python3 runtime dependencies
# - If any are found, ensures that the base python3 package is included
# - Restricts the python3 version to the same minor specified in $py3_ver

hook() {
    [ -d "${PKGDESTDIR}/${py3_lib}" ] || return 0
    [ "${pkgname}" = python3 ] && return 0

    local dep rdeps
    for dep in ${run_depends}; do
        case "${dep}" in
            python3 | "python3>"* | "python3<"* | "python3-${py3_ver}"* ) ;;
            *) rdeps+=( "${dep}" ) ;;
        esac
    done

    local minor next_minor

    minor="${py3_ver#3.}"
    next_minor="$(( "${minor}" + 1 ))" >/dev/null 2>&1 || next_minor=

    if ! [ "${next_minor}" -gt "${minor}" ]; then
        msg_error 'unable to determine python3 minor bounds from $py3_ver\n'
    fi

    rdeps+=( "python3>=3.${minor}.0_1<3.${next_minor}.0_1" )
    run_depends="${rdeps[*]}"
}
