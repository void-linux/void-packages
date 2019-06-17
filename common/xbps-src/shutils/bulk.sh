# vim: set ts=4 sw=4 et:

bulk_getlink() {
    local p="${1##*/}"
    local target="$(readlink $XBPS_SRCPKGDIR/$p)"

    if [ $? -eq 0 -a -n "$target" ]; then
        p=$target
    fi
    echo $p
}

bulk_sortdeps() {
    local _pkgs _pkg pkgs pkg found f x tmpf

    _pkgs="$@"
    # Iterate over the list and make sure that only real pkgs are
    # added to our pkglist.
    for pkg in ${_pkgs}; do
        found=0
        f=$(bulk_getlink $pkg)
        for x in ${pkgs}; do
            if [ "$x" = "${f}" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            pkgs+="${f} "
        fi
    done

    tmpf=$(mktemp || exit 1)
    # Now make the real dependency graph of all pkgs to build.
    # Perform a topological sort of all pkgs but only with build dependencies
    # that are found in previous step.
    for pkg in ${pkgs}; do
        _pkgs="$(./xbps-src show-build-deps $pkg 2>/dev/null)"
        found=0
        for x in ${_pkgs}; do
            _pkg=$(bulk_getlink $x)
            for f in ${pkgs}; do
                if [ "${f}" != "${_pkg}" ]; then
                    continue
                fi
                found=1
                echo "${pkg} ${f}" >> $tmpf
            done
        done
        [ $found -eq 0 ] && echo "${pkg} ${pkg}" >> $tmpf
    done
    tsort $tmpf|tac
    rm -f $tmpf
}

bulk_build() {

    if [ "$XBPS_CROSS_BUILD" ]; then
        source ${XBPS_COMMONDIR}/cross-profiles/${XBPS_CROSS_BUILD}.sh
        export XBPS_ARCH=${XBPS_TARGET_MACHINE}
    fi
    if ! command -v xbps-checkvers &>/dev/null; then
        msg_error "xbps-src: cannot find xbps-checkvers(8) command!\n"
    fi

    bulk_sortdeps "$(xbps-checkvers ${1} --distdir=$XBPS_DISTDIR | awk '{print $2}')"
}

bulk_update() {
    local args="$1" pkgs f rval

    pkgs="$(bulk_build ${args})"
    if [ -z "$pkgs" ]; then
        return 0
    fi
    msg_normal "xbps-src: the following packages must be rebuilt and updated:\n"
    for f in ${pkgs}; do
        echo "   $f"
    done
    echo
    for f in ${pkgs}; do
        XBPS_TARGET_PKG=$f
        read_pkg
        msg_normal "xbps-src: building ${pkgver} ...\n"
        if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
            chroot_handler pkg $XBPS_TARGET_PKG
        else
            $XBPS_LIBEXECDIR/build.sh $f $f pkg $XBPS_CROSS_BUILD
        fi
        if [ $? -eq 1 ]; then
            msg_error "xbps-src: failed to build $pkgver pkg!\n"
        fi
    done
    if [ -n "$pkgs" -a -n "$args" ]; then
        echo
        msg_normal "xbps-src: updating your system, confirm to proceed...\n"
        ${XBPS_SUCMD} "xbps-install --repository=$XBPS_REPOSITORY --repository=$XBPS_REPOSITORY/nonfree -u ${pkgs}" || return 1
    fi
}
