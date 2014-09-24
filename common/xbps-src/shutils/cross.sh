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

install_cross_pkg() {
    local cross="$1" rval errlog

    [ -z "$cross" -o "$cross" = "" ] && return 0

    source_file ${XBPS_CROSSPFDIR}/${cross}.sh

    if [ -z "$CHROOT_READY" ]; then
        echo "ERROR: chroot mode not activated (install a bootstrap)."
        exit 1
    elif [ -z "$IN_CHROOT" ]; then
        return 0
    fi

    # Install required pkgs for cross building.
    if [ "$XBPS_TARGET" != "remove-autodeps" ]; then
        errlog=$(mktemp)
        check_installed_pkg cross-${XBPS_CROSS_TRIPLET}-0.1_1
        if [ $? -ne 0 ]; then
            msg_normal "Installing cross pkg: cross-${XBPS_CROSS_TRIPLET} ...\n"
            $XBPS_INSTALL_CMD -Syd cross-${XBPS_CROSS_TRIPLET} &>$errlog
            rval=$?
            if [ $rval -ne 0 -a $rval -ne 17 ]; then
                msg_red "failed to install cross-${XBPS_CROSS_TRIPLET} (error $rval)\n"
                cat $errlog
                rm -f $errlog
                msg_error "cannot continue due to errors above\n"
            fi
        fi
        if [ ! -d ${XBPS_CROSS_BASE}/var/db/xbps/keys ]; then
            mkdir -p ${XBPS_CROSS_BASE}/var/db/xbps/keys
            cp ${XBPS_MASTERDIR}/var/db/xbps/keys/*.plist \
                ${XBPS_CROSS_BASE}/var/db/xbps/keys
        fi
        $XBPS_INSTALL_CMD -r ${XBPS_CROSS_BASE} -SAyd cross-vpkg-dummy &>$errlog
        rval=$?
        if [ $rval -ne 0 -a $rval -ne 17 ]; then
            msg_red "failed to install cross-vpkg-dummy (error $rval)\n"
            cat $errlog
            rm -f $errlog
            msg_error "cannot continue due to errors above\n"
        fi
    fi
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
