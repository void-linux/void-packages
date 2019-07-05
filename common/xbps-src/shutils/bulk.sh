# vim: set ts=4 sw=4 et:

bulk_sortdeps() {
    local pkgs="$@"
    local pkg _pkg
    local NPROCS=$(($(nproc)*2))
    local NRUNNING=0

    tmpf=$(mktemp) || exit 1

    # Perform a topological sort of all build dependencies.
    if [ $NRUNNING -eq $NPROCS ]; then
        NRUNNING=0
        wait
    fi

    for pkg in ${pkgs}; do
        # async/parallel execution
        (
            for _pkg in $(./xbps-src show-build-deps $pkg 2>/dev/null); do
                echo "$pkg $_pkg" >> $tmpf
            done
            echo "$pkg $pkg" >> $tmpf
        ) &
    done
    wait
    tsort $tmpf|tac
    rm -f $tmpf
}

bulk_build() {

    if [ "$XBPS_CROSS_BUILD" ]; then
        source ${XBPS_COMMONDIR}/cross-profiles/${XBPS_CROSS_BUILD}.sh
        export XBPS_ARCH=${XBPS_TARGET_MACHINE}
    fi
    if ! command -v xbps-checkvers &>/dev/null; then
        msg_error "xbps-src: cannot find xbps-checkvers(1) command!\n"
    fi

    bulk_sortdeps "$(xbps-checkvers -f '%n' ${1} --distdir=$XBPS_DISTDIR)"
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
