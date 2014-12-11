# vim: set ts=4 sw=4 et:

check_pkg_arch() {
    local cross="$1"

    if [ -n "$BEGIN_INSTALL" -a -n "$only_for_archs" ]; then
        if [ -n "$cross" ]; then
            _arch="$XBPS_TARGET_MACHINE"
        elif [ -n "$XBPS_ARCH" ]; then
            _arch="$XBPS_ARCH"
        else
            _arch="$XBPS_MACHINE"
        fi
        for f in ${only_for_archs}; do
            if [ "$f" = "${_arch}" ]; then
                found=1
                break
            fi
        done
        if [ -z "$found" ]; then
            msg_red "$pkgname: this package cannot be built for ${_arch}.\n"
            exit 0
        fi
    fi
}

install_pkg() {
    local target="$1" cross="$2" lrepo subpkg opkg

    [ -z "$pkgname" ] && return 1

    show_pkg_build_options
    check_pkg_arch $cross
    install_cross_pkg $cross

    if [ -z "$XBPS_SKIP_DEPS" ]; then
        install_pkg_deps $sourcepkg $cross || return 1
        if [ "$TARGETPKG_PKGDEPS_DONE" ]; then
            setup_pkg $XBPS_TARGET_PKG $cross
            unset TARGETPKG_PKGDEPS_DONE
            install_cross_pkg $cross
        fi
    fi

    # Fetch distfiles after installing required dependencies,
    # because some of them might be required for do_fetch().
    $XBPS_LIBEXECDIR/xbps-src-dofetch.sh $sourcepkg $cross || exit 1
    [ "$target" = "fetch" ] && return 0

    # Fetch, extract, build and install into the destination directory.
    $XBPS_LIBEXECDIR/xbps-src-doextract.sh $sourcepkg $cross || exit 1
    [ "$target" = "extract" ] && return 0

    # Run configure phase
    $XBPS_LIBEXECDIR/xbps-src-doconfigure.sh $sourcepkg $cross || exit 1
    [ "$target" = "configure" ] && return 0

    # Run build phase
    $XBPS_LIBEXECDIR/xbps-src-dobuild.sh $sourcepkg $cross || exit 1
    [ "$target" = "build" ] && return 0

    # Install pkgs into destdir.
    $XBPS_LIBEXECDIR/xbps-src-doinstall.sh $sourcepkg $cross || exit 1

    for subpkg in ${subpackages} ${sourcepkg}; do
        $XBPS_LIBEXECDIR/xbps-src-doinstall.sh $subpkg $cross || exit 1
    done
    for subpkg in ${subpackages} ${sourcepkg}; do
        $XBPS_LIBEXECDIR/xbps-src-prepkg.sh $subpkg $cross || exit 1
    done

    for subpkg in ${subpackages} ${sourcepkg}; do
        if [ "$XBPS_TARGET_PKG" = "${subpkg}" -a "$target" = "install" ]; then
            return 0
        fi
    done

    # If install went ok generate the binpkgs.
    for subpkg in ${subpackages} ${sourcepkg}; do
        $XBPS_LIBEXECDIR/xbps-src-dopkg.sh $subpkg "$XBPS_REPOSITORY" "$cross" || exit 1
    done

    # pkg cleanup
    if declare -f do_clean >/dev/null; then
        run_func do_clean
    fi

    opkg=$pkgver
    if [ -z "$XBPS_KEEP_ALL" ]; then
        remove_pkg_autodeps
        remove_pkg_wrksrc
        setup_pkg $sourcepkg $cross
        remove_pkg $cross
    fi

    # If base-chroot not installed, install "base-files" into masterdir
    # from local repository; this is the only pkg required to be able to build
    # the bootstrap pkgs from scratch.
    if [ -z "$CHROOT_READY" -a "$pkgname" = "base-files" ]; then
        msg_normal "Installing $opkg into masterdir...\n"
        local _log=$(mktemp --tmpdir|| exit 1)
        if [ -n "$XBPS_BUILD_FORCEMODE" ]; then
            local _flags="-f"
        fi
        $XBPS_INSTALL_CMD ${_flags} -y $opkg >${_log} 2>&1
        if [ $? -ne 0 ]; then
            msg_red "Failed to install $opkg into masterdir, see below for errors:\n"
            cat ${_log}
            rm -f ${_log}
            msg_error "Cannot continue!"
        fi
        rm -f ${_log}
    fi

    if [ "$XBPS_TARGET_PKG" = "$sourcepkg" -a "$XBPS_TARGET" != "bootstrap" ]; then
        # Package built successfully. Exit directly due to nested install_pkg
        # and install_pkg_deps functions.
        remove_cross_pkg $cross
        exit 0
    fi
}

remove_pkg_autodeps() {
    local rval= tmplogf=

    cd $XBPS_MASTERDIR || return 1
    msg_normal "${pkgver:-xbps-src}: removing autodeps, please wait...\n"
    tmplogf=$(mktemp)

    if [ -z "$CHROOT_READY" ]; then
        xbps-reconfigure -r $XBPS_MASTERDIR -a >> $tmplogf 2>&1
        xbps-remove -r $XBPS_MASTERDIR -Ryo >> $tmplogf 2>&1
    else
        remove_pkg_cross_deps
        xbps-reconfigure -a >> $tmplogf 2>&1
        xbps-remove -Ryo >> $tmplogf 2>&1
    fi

    if [ $? -ne 0 ]; then
        msg_red "${pkgver:-xbps-src}: failed to remove autodeps:\n"
        cat $tmplogf && rm -f $tmplogf
        msg_error "${pkgver:-xbps-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
}

remove_pkg_wrksrc() {
    if [ -d "$wrksrc" ]; then
        msg_normal "$pkgver: cleaning build directory...\n"
        rm -rf $wrksrc
    fi
}

remove_pkg() {
    local cross="$1" _destdir f

    [ -z $pkgname ] && msg_error "unexistent package, aborting.\n"

    if [ -n "$cross" ]; then
        _destdir="$XBPS_DESTDIR/$XBPS_CROSS_TRIPLET"
    else
        _destdir="$XBPS_DESTDIR"
    fi

    [ ! -d ${_destdir} ] && return

    for f in ${sourcepkg} ${subpackages}; do
        if [ -d "${_destdir}/${f}-${version}" ]; then
            msg_normal "$f: removing files from destdir...\n"
            rm -rf ${_destdir}/${f}-${version}
        fi
        if [ -d "${_destdir}/${f}-dbg-${version}" ]; then
            msg_normal "$f: removing dbg files from destdir...\n"
            rm -rf ${_destdir}/${f}-dbg-${version}
        fi
        if [ -d "${_destdir}/${f}-32bit-${version}" ]; then
            msg_normal "$f: removing 32bit files from destdir...\n"
            rm -rf ${_destdir}/${f}-32bit-${version}
        fi
        rm -f ${XBPS_STATEDIR}/${f}_${cross}_subpkg_install_done
        rm -f ${XBPS_STATEDIR}/${f}_${cross}_prepkg_done
    done
    rm -f ${XBPS_STATEDIR}/${sourcepkg}_${cross}_install_done
    rm -f ${XBPS_STATEDIR}/${sourcepkg}_${cross}_pre_install_done
    rm -f ${XBPS_STATEDIR}/${sourcepkg}_${cross}_post_install_done
}
