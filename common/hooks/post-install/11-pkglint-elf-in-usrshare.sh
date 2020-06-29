# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#   - Looks on all packages for binary files being installed to /usr/share

hook() {
    local matches mime file

    if [ ! -d ${PKGDESTDIR}/usr/share ]; then
        return 0
    fi

    # Find all binaries in /usr/share and add them to the pool
    while read -r f; do
        mime="${f##*:}"
        mime="${mime// /}"
        file="${f%:*}"
        case "${mime}" in
            # Note application/x-executable is missing which is present in most Electron apps
            application/x-sharedlib*|application/x-pie-executable*)
                matches+=" ${file#$PKGDESTDIR}" ;;
        esac
    done < <(find $PKGDESTDIR/usr/share -type f | file --mime-type --files-from -)

    if [ -z "$matches" ]; then
        return 0
    fi

    msg_red "${pkgver}: ELF files found in /usr/share:\n"
    for f in $matches; do
        msg_red "   ${f}\n"
    done
    msg_error "${pkgver}: cannot continue with installation!\n"
}
