# vim: set ts=4 sw=4 et:
#
# This hooks executes the following tasks:
#	- Checks files in DESTDIR for binary files and .so symlink on /usr/lib
#	- Suggest adding or removing whether binary files were found

hook() {
    local found

    for file in $(find ${PKGDESTDIR} -type f -o -type l); do
        case "$(file -bi -- "$file")" in
            application/x-*executable*|x-sharedlib*)
                found=1
                break
                ;;
        esac
    done

    # Try to find .so solink
    if [[ -n $(find $PKGDESTDIR/usr/lib -maxdepth 1 -type l -iname '*.so') ]]; then
        found=1
    fi

    if [ -z "$found" -a -z "$noarch" ]; then
        msg_warn "$pkgver: doesn't contain machine code, candiate for noarch\n"
    fi

    if [ -n "$found" -a -n "$noarch" ]; then
        msg_warn "$pkgver: noarch but contains machine code\n"
    fi
}
