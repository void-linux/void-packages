# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#   - Looks on non -devel packages for files that should be in the -devel package
#   - Searches for solinks (.so) and archives (.a) on usr/lib
#   - Searches for executables in usr/bin that end with -config and a respective manpage

hook() {
    local solink archive

    if [[ "$pkgname" == *"-devel" ]]; then
        return 0
    fi

    if [[ "$subpackages" != *"-devel" ]]; then
        return 0
    fi

    for f in $(find $PKGDESTDIR -type d); do
        case "${f#$PKGDESTDIR}" in
            /usr/include)
                msg_warn "usr/include should be in -devel package\n"
                ;;
            /usr/share/pkgconfig)
                msg_warn "usr/share/pkgconfig should be in -devel package\n"
                ;;
            /usr/lib/pkgconfig)
                msg_warn "usr/lib/pkgconfig should be in -devel package\n"
                ;;
            /usr/share/vala)
                msg_warn "usr/share/vala should be in -devel package\n"
                ;;
            /usr/share/gir-1.0)
                msg_warn "usr/share/gir-1.0 should be in -devel package\n"
                ;;
            /usr/share/man/man3)
                msg_warn "usr/share/man/man3 should be in -devel package\n"
                ;;
            /usr/share/aclocal)
                msg_warn "usr/share/aclocal should be in -devel package\n"
                ;;
            /usr/share/cmake)
                msg_warn "usr/share/cmake should be in -devel package\n"
                ;;
            /usr/lib/cmake)
                msg_warn "usr/lib/cmake should be in -devel package\n"
                ;;
            /usr/share/gtk-doc)
                msg_warn "usr/share/gtk-doc should be in -devel package\n"
                ;;
            /usr/lib/qt5/mkspecs)
                msg_warn "usr/lib/qt5/mkspecs should be in -devel package\n"
                ;;
        esac

        if [ -n "$(find $PKGDESTDIR/usr/lib -maxdepth 1 -type l -iname '*.so' 2>/dev/null)" ]; then
            solink=1
        fi

        if [ -n "$(find $PKGDESTDIR/usr/lib -maxdepth 1 -type f -iname '*.a' 2>/dev/null)" ]; then
            archive=1
        fi

        if [ -d $PKGDESTDIR/usr/bin ]; then
            for x in $(find $PKGDESTDIR/usr/bin -type f -executable -iname '*-config'); do
                msg_warn "${x#$PKGDESTDIR\/} should be in -devel package\n"
            done
        fi

        if [ -d $PKGDESTDIR/usr/man/man1 ]; then
            for m in $(find $PKGDESTDIR/usr/man/man1 -type f -iname '*-config.1'); do
                msg_warn "${m#$PKGDESTDIR\/} should be in -devel package\n"
            done
        fi

    done

    if [ -n "$solink" ]; then
        msg_warn "usr/lib/*.so should be in -devel package\n"
    fi

    if [ -n "$archive" ]; then
        msg_warn "usr/lib/*.a should be in -devel package\n"
    fi
}
