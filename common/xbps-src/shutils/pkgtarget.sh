# vim: set ts=4 sw=4 et:

check_existing_pkg() {
    local arch= curpkg=
    if [ -z "$XBPS_PRESERVE_PKGS" ] || [ "$XBPS_BUILD_FORCEMODE" ]; then
        return
    fi
    arch=$XBPS_TARGET_MACHINE
    curpkg=$XBPS_REPOSITORY/$repository/$pkgver.$arch.xbps
    if [ -e $curpkg ]; then
        msg_warn "$pkgver: skipping build due to existing $curpkg\n"
        exit 0
    fi
}

check_pkg_arch() {
    local cross="$1" _arch f match nonegation

    if [ -n "$archs" ]; then
        if [ -n "$cross" ]; then
            _arch="$XBPS_TARGET_MACHINE"
        elif [ -n "$XBPS_ARCH" ]; then
            _arch="$XBPS_ARCH"
        else
            _arch="$XBPS_MACHINE"
        fi
        set -f
        for f in ${archs}; do
            set +f
            nonegation=${f##\~*}
            f=${f#\~}
            case "${_arch}" in
                $f) match=1; break ;;
            esac
        done
        if [ -z "$nonegation" -a -n "$match" ] || [ -n "$nonegation" -a -z "$match" ]; then
            report_broken "${pkgname}-${version}_${revision}: this package cannot be built for ${_arch}.\n"
        fi
    fi
}

# Returns 1 if pkg is available in xbps repositories, 0 otherwise.
pkg_available() {
    local pkg="$1" cross="$2" pkgver

    if [ -n "$cross" ]; then
        pkgver=$($XBPS_QUERY_XCMD -R -ppkgver "${pkg}" 2>/dev/null)
    else
        pkgver=$($XBPS_QUERY_CMD -R -ppkgver "${pkg}" 2>/dev/null)
    fi

    if [ -z "$pkgver" ]; then
        return 0
    fi
    return 1
}

remove_pkg_autodeps() {
    local rval= tmplogf= errlogf= prevs=

    cd $XBPS_MASTERDIR || return 1
    msg_normal "${pkgver:-xbps-src}: removing autodeps, please wait...\n"
    tmplogf=$(mktemp) || exit 1
    errlogf=$(mktemp) || exit 1

    remove_pkg_cross_deps
    $XBPS_RECONFIGURE_CMD -a >> $tmplogf 2>&1
    prevs=$(stat -c %s $tmplogf)
    echo yes | $XBPS_REMOVE_CMD -Ryod 2>> $errlogf 1>> $tmplogf
    rval=$?
    while [ $rval -eq 0 ]; do
        local curs=$(stat -c %s $tmplogf)
        if [ $curs -eq $prevs ]; then
            break
        fi
        prevs=$curs
        echo yes | $XBPS_REMOVE_CMD -Ryod 2>> $errlogf 1>> $tmplogf
        rval=$?
    done

    if [ $rval -ne 0 ]; then
        msg_red "${pkgver:-xbps-src}: failed to remove autodeps: (returned $rval)\n"
        cat $tmplogf && rm -f $tmplogf
        cat $errlogf && rm -f $errlogf
        msg_error "${pkgver:-xbps-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
    rm -f $errlogf
}

remove_pkg_wrksrc() {
    if [ -d "$wrksrc" ]; then
        msg_normal "$pkgver: cleaning build directory...\n"
        rm -rf "$wrksrc" 2>/dev/null || chmod -R +wX "$wrksrc" # Needed to delete Go Modules
        rm -rf "$wrksrc"
    fi
}

remove_pkg_statedir() {
    if [ -d "$XBPS_STATEDIR" ]; then
        rm -rf "$XBPS_STATEDIR"
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
