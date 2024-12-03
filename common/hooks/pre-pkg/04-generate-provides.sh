# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#	- Generates provides file with provides entries for xbps-create(1)

hook() {
    local -a _provides=()

    # include explicit values from the template
    read -r -a _provides <<< "$provides"

    if [ "${#_provides[@]}" -gt 0 ]; then
        echo "   ${_provides[*]}"
        echo "${_provides[*]}" > "${PKGDESTDIR}/provides"
    fi
}
