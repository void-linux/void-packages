# vim: set ts=4 sw=4 et:

consistency_check_existing () {
    while IFS=" " read -r dep origname deplabel; do
        [ -f "$XBPS_SRCPKGDIR/$dep/template" ] && continue
        case "$deplabel" in
            makedepends|hostmakedepends|checkdepends)
                msg_warn "unsatisfied $deplabel in $origname: $dep does not exist\n";
                ;;
            *) printf "%s %s %s\n" "$dep" "$origname" "$deplabel" ;;
        esac
    done
}

consistency_convert_pkgname () {
    local origname= pkgname version= revision=
    while IFS=" " read -r dep origname deplabel; do
        case "$deplabel" in
            makedepends|hostmakedepends|checkdepends)
                printf "%s %s %s\n" "$dep" "$origname" "$deplabel"
                continue
                ;;
        esac
        case "$dep" in
            *\<*|*\>*|*=*)
                printf "%s %s %s\n" "$dep" "$origname" "$deplabel"
                continue
                ;;
        esac
        if pkgname=$(xbps-uhelper getpkgname "$dep" 2> /dev/null) && \
            version=$(xbps-uhelper getpkgversion "$dep" 2> /dev/null) && \
            revision=$(xbps-uhelper getpkgrevision "$dep" 2> /dev/null); then
            printf "%s %s %s\n" "${pkgname}>=${version}_${revision}" "$origname" "$deplabel"
        else
            printf "%s %s %s\n" "$dep>=0" "$origname" "$deplabel"
        fi
    done
}

consistency_check_smart () {
    local pkgname= depdef= dep=
    while IFS=" " read -r depdef origname deplabel; do
        case "$deplabel" in
            makedepends|hostmakedepends|checkdepends)
                printf "%s %s %s\n" "$depdef" "$origname" "$deplabel"
                continue
                ;;
        esac

        dep=$(xbps-uhelper getpkgdepname "$depdef")

        if [ ! -f "$XBPS_SRCPKGDIR/$dep/template" ]; then
            msg_warn "unsatisfied $deplabel in $origname: $dep does not exist\n";
            continue
        fi
        (
            XBPS_TARGET_PKG=$dep
            read_pkg
            xbps-uhelper pkgmatch "$depdef" "${pkgname}-${version}_${revision}" && return
            msg_red "unsatisfied $deplabel in $origname: $dep is $version, but required is $depdef\n";
        )
    done
}

consistency_check() {
    local pkg= pkgname=
    for pkg in "$XBPS_SRCPKGDIR"/*/template; do
        pkg=${pkg%/*}
        XBPS_TARGET_PKG=${pkg##*/}
        (
            read_pkg
            [ "$depends" ] && printf "%s $pkgname depends\n" $depends
            [ "$conflicts" ] && printf "%s $pkgname conflicts\n" $conflicts
            [ -L "$XBPS_SRCPKGDIR/$XBPS_TARGET_PKG" ] && return
            [ "$makedepends" ] && printf "%s $pkgname makedepends\n" $makedepends
            [ "$hostmakedepends" ] && printf "%s $pkgname hostmakedepends\n" $hostmakedepends
            [ "$checkdepends" ] && printf "%s $pkgname checkdepends\n" $checkdepends
        )
    done | grep -v "^virtual?" | sed "s/^[^ ]*?//" | consistency_check_existing | \
        consistency_convert_pkgname | consistency_check_smart
}
