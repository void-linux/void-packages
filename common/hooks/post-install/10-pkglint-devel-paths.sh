# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#   - Looks on non -devel packages for files that should be in the -devel package
#   - Searches for solinks (.so) and archives (.a) on usr/lib
#   - Searches for executables in usr/bin that end with -config and a respective manpage

annotate_lint_devel() {
    msg_warn "$*\n"
    [ "$XBPS_BUILD_ENVIRONMENT" = "void-packages-ci" ] || return 0
    local _lineno=$(awk '/${pkgname}_package/ {print FNR}' "${XBPS_SRCPKGDIR}/${sourcepkg}/template")
    printf "\n::warning file=srcpkgs/${sourcepkg}/template,line=${_lineno},title=$*::$*\n"
}

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
                annotate_lint_devel "usr/include should be in -devel package"
                ;;
            /usr/share/pkgconfig)
                annotate_lint_devel "usr/share/pkgconfig should be in -devel package"
                ;;
            /usr/lib/pkgconfig)
                annotate_lint_devel "usr/lib/pkgconfig should be in -devel package"
                ;;
            /usr/share/vala)
                annotate_lint_devel "usr/share/vala should be in -devel package"
                ;;
            /usr/share/gir-1.0)
                annotate_lint_devel "usr/share/gir-1.0 should be in -devel package"
                ;;
            /usr/share/man/man3)
                annotate_lint_devel "usr/share/man/man3 should be in -devel package"
                ;;
            /usr/share/aclocal)
                annotate_lint_devel "usr/share/aclocal should be in -devel package"
                ;;
            /usr/share/cmake)
                annotate_lint_devel "usr/share/cmake should be in -devel package"
                ;;
            /usr/lib/cmake)
                annotate_lint_devel "usr/lib/cmake should be in -devel package"
                ;;
            /usr/share/gtk-doc)
                annotate_lint_devel "usr/share/gtk-doc should be in -devel package"
                ;;
            /usr/lib/qt5/mkspecs)
                annotate_lint_devel "usr/lib/qt5/mkspecs should be in -devel package"
                ;;
        esac
    done

    if [ -n "$(find $PKGDESTDIR/usr/lib -maxdepth 1 -type l -iname '*.so' 2>/dev/null)" ]; then
        solink=1
    fi

    if [ -n "$(find $PKGDESTDIR/usr/lib -maxdepth 1 -type f -iname '*.a' 2>/dev/null)" ]; then
        archive=1
    fi

    if [ -d $PKGDESTDIR/usr/bin ]; then
        for x in $(find $PKGDESTDIR/usr/bin -type f -executable -iname '*-config'); do
            annotate_lint_devel "${x#$PKGDESTDIR\/} should be in -devel package"
        done
    fi

    if [ -d $PKGDESTDIR/usr/man/man1 ]; then
        for m in $(find $PKGDESTDIR/usr/man/man1 -type f -iname '*-config.1'); do
            annotate_lint_devel "${m#$PKGDESTDIR\/} should be in -devel package"
        done
    fi

    if [ -n "$solink" ]; then
        annotate_lint_devel "usr/lib/*.so should be in -devel package"
    fi

    if [ -n "$archive" ]; then
        annotate_lint_devel "usr/lib/*.a should be in -devel package"
    fi
}
