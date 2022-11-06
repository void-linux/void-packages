# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#   - Looks on all packages for binary files being installed to /usr/share
#   - Allows exceptions listed in $ignore_elf_files and $ignore_elf_dirs

hook() {
    local matches mime file f prune_expr dir

    if [ ! -d ${PKGDESTDIR}/usr/share ]; then
        return 0
    fi

    if [ "${ignore_elf_dirs}" ]; then
        for dir in ${ignore_elf_dirs}; do
            if ! [ "${prune_expr}" ]; then
                prune_expr="( -path ${PKGDESTDIR}${dir}"
            else
                prune_expr+=" -o -path ${PKGDESTDIR}${dir}"
            fi
        done
        prune_expr+=" ) -prune -o "
    fi

    # Find all binaries in /usr/share and add them to the pool
    while read -r f; do
        mime="${f##*: }"
        file="${f%:*}"
        file="${file#${PKGDESTDIR}}"
        case "${mime}" in
            application/x-sharedlib*|\
             application/x-pie-executable*|\
             application/x-executable*)
                if [[ ${ignore_elf_files} != *"${file}"* ]]; then
                    matches+=" ${file}"
                fi
                ;;
        esac
    done < <(find $PKGDESTDIR/usr/share $prune_expr -type f | file --no-pad --mime-type --files-from -)

    # Check passed if no packages in pool
    if [ -z "$matches" ]; then
        return 0
    fi

    msg_red "${pkgver}: ELF files found in /usr/share:\n"
    for f in $matches; do
        msg_red "   ${f}\n"
    done
    msg_error "${pkgver}: cannot continue with installation!\n"
}
