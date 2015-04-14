# vim: set ts=4 sw=4 et:

remove_pkg_cross_deps() {
    local rval= tmplogf=
    [ -z "$XBPS_CROSS_BUILD" ] && return 0

    cd $XBPS_MASTERDIR || return 1
    msg_normal "${pkgver:-xbps-src}: removing autocrossdeps, please wait...\n"
    tmplogf=$(mktemp)

    if [ -z "$XBPS_REMOVE_XCMD" ]; then
        source_file $XBPS_CROSSPFDIR/${XBPS_CROSS_BUILD}.sh
        XBPS_REMOVE_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH xbps-remove -r /usr/$XBPS_CROSS_TRIPLET"
    fi

    $XBPS_REMOVE_XCMD -Ryo > $tmplogf 2>&1
    if [ $? -ne 0 ]; then
        msg_red "${pkgver:-xbps-src}: failed to remove autocrossdeps:\n"
        cat $tmplogf && rm -f $tmplogf
        msg_error "${pkgver:-xbps-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
}

prepare_cross_sysroot() {
    local cross="$1"

    [ -z "$cross" -o "$cross" = "" ] && return 0

    # Check for cross-vpkg-dummy available for the target arch, otherwise build it.
    pkg_available cross-vpkg-dummy $cross
    if [ $? -eq 0 ]; then
        $XBPS_LIBEXECDIR/build.sh cross-vpkg-dummy cross-vpkg-dummy pkg $cross init || return $?
    fi

    check_installed_pkg cross-vpkg-dummy-0.17_1 $cross
    [ $? -eq 0 ] && return 0

    msg_normal "Installing $cross cross pkg: cross-vpkg-dummy ...\n"
    errlog=$(mktemp)
    $XBPS_INSTALL_XCMD -SAyfd cross-vpkg-dummy &>$errlog
    rval=$?
    if [ $rval -ne 0 -a $rval -ne 17 ]; then
        msg_red "failed to install cross-vpkg-dummy (error $rval)\n"
        cat $errlog
        rm -f $errlog
        msg_error "cannot continue due to errors above\n"
    fi
    rm -f $errlog

    return 0
}

install_cross_pkg() {
    local cross="$1" rval errlog

    [ -z "$cross" -o "$cross" = "" ] && return 0

    # Check if the cross compiler pkg is available in repos, otherwise build it.
    pkg_available cross-${XBPS_CROSS_TRIPLET}
    rval=$?
    if [ $rval -eq 0 ]; then
        $XBPS_LIBEXECDIR/build.sh cross-${XBPS_CROSS_TRIPLET} cross-${XBPS_CROSS_TRIPLET} pkg || return $rval
    fi

    check_installed_pkg cross-${XBPS_CROSS_TRIPLET}-0.1_1
    [ $? -eq 0 ] && return 0

    errlog=$(mktemp)
    msg_normal "Installing $cross cross compiler: cross-${XBPS_CROSS_TRIPLET} ...\n"
    $XBPS_INSTALL_CMD -Syfd cross-${XBPS_CROSS_TRIPLET} &>$errlog
    rval=$?
    if [ $rval -ne 0 -a $rval -ne 17 ]; then
        msg_red "failed to install cross-${XBPS_CROSS_TRIPLET} (error $rval)\n"
        cat $errlog
        rm -f $errlog
        msg_error "cannot continue due to errors above\n"
    fi
    rm -f $errlog

    return 0
}

remove_cross_pkg() {
    local cross="$1" rval

    [ -z "$cross" -o "$cross" = "" ] && return 0

    source_file ${XBPS_CROSSPFDIR}/${cross}.sh

    if [ -z "$CHROOT_READY" ]; then
        echo "ERROR: chroot mode not activated (install a bootstrap)."
        exit 1
    elif [ -z "$IN_CHROOT" ]; then
        return 0
    fi

    msg_normal "Removing cross pkg: cross-${XBPS_CROSS_TRIPLET} ...\n"
    $XBPS_REMOVE_CMD -Ry cross-${XBPS_CROSS_TRIPLET} &>/dev/null
    rval=$?
    if [ $rval -ne 0 ]; then
        msg_error "failed to remove cross-${XBPS_CROSS_TRIPLET} (error $rval)\n"
    fi
}
