# vim: set ts=4 sw=4 et:

bulk_getlink() {
    local p="$(basename $1)"
    local target="$(readlink $XBPS_SRCPKGDIR/$p)"

    if [ $? -eq 0 -a -n "$target" ]; then
        p=$target
    fi
    echo $p
}

bulk_build() {
    local args="$1" pkg= pkgs= _pkgs= _realdep= _deps= found= x= result=

    if ! command -v xbps-checkvers &>/dev/null; then
        msg_error "xbps-src: cannot find xbps-checkvers(8) command!\n"
    fi
    _pkgs=$(xbps-checkvers ${args} -d $XBPS_DISTDIR | awk '{print $2}')
    # Only add to the list real pkgs, not subpkgs.
    for pkg in ${_pkgs}; do
        _realdep=$(bulk_getlink $pkg)
        unset found
        for x in ${pkgs}; do
            if [ "$x" = "${_realdep}" ]; then
                found=1
                break
            fi
        done
        if [ -z "$found" ]; then
            pkgs="$pkgs ${_realdep}"
        fi
    done
    for pkg in ${pkgs}; do
        unset found
        setup_pkg $pkg $XBPS_CROSS_BUILD
        _deps="$(show_pkg_build_deps | sed -e 's|[<>].*\$||g')"
        _realdep=$(bulk_getlink $pkg)
        for x in ${_deps}; do
            if [ "${_realdep}" = "${pkg}" ]; then
                found=1
                break
            fi
        done
        [ -n $found ] && result="${_realdep} ${result}"
    done
    [ -n "$result" ] && echo "$result"
}

bulk_update() {
    local args="$1" pkgs=

    pkgs="$(bulk_build ${args})"
    msg_normal "xbps-src: the following packages must be rebuilt and updated:\n"
    for f in ${pkgs}; do
        echo "   $f"
    done
    echo
    for f in ${pkgs}; do
        BEGIN_INSTALL=1
        XBPS_TARGET_PKG="$f"
        read_pkg
        msg_normal "xbps-src: building ${pkgver} ...\n"
        if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
            chroot_handler pkg $XBPS_TARGET_PKG
        else
            install_pkg pkg $XBPS_CROSS_BUILD
        fi
        if [ $? -ne 0 ]; then
            msg_error "xbps-src: failed to build $pkgver pkg!\n"
        fi
    done
    if [ -n "$pkgs" -a -n "$args" ]; then
        echo
        msg_normal "xbps-src: updating your system, confirm to proceed...\n"
        ${XBPS_SUCMD} "xbps-install --repository=$XBPS_REPOSITORY --repository=$XBPS_REPOSITORY/nonfree -u ${pkgs}"
    fi
}
