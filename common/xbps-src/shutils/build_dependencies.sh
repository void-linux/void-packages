# vim: set ts=4 sw=4 et:
#
setup_pkg_depends() {
    local pkg="$1" out="$2" j _rpkgname _depname _pkgname foo _deps

    if [[ $pkg ]]; then
        # subpkg
        if declare -f ${pkg}_package >/dev/null; then
            ${pkg}_package
        fi
    fi

    for j in ${depends}; do
        _rpkgname="${j%\?*}"
        _depname="${j#*\?}"
        if [[ ${_rpkgname} == virtual ]]; then
            _pkgname=$(xbps-uhelper getpkgname $_depname 2>/dev/null)
            [ -z "$_pkgname" ] && _pkgname="$_depname"
            if [ -s ${XBPS_DISTDIR}/etc/virtual ]; then
                foo=$(egrep "^${_pkgname}[[:blank:]]" ${XBPS_DISTDIR}/etc/virtual|cut -d ' ' -f2)
            elif [ -s ${XBPS_DISTDIR}/etc/defaults.virtual ]; then
                foo=$(egrep "^${_pkgname}[[:blank:]]" ${XBPS_DISTDIR}/etc/defaults.virtual|cut -d ' ' -f2)
            fi
            if [ -z "$foo" ]; then
                msg_error "$pkgver: failed to resolve virtual dependency for '$j' (missing from etc/virtual)\n"
            fi
            _deps+="$foo "
        else
            foo="$($XBPS_UHELPER_CMD getpkgdepname ${_depname} 2>/dev/null)"
            if [ -z "$foo" ]; then
                foo="$($XBPS_UHELPER_CMD getpkgname ${_depname} 2>/dev/null)"
                [ -z "$foo" ] && foo="${_depname}"
            fi
            _deps+="$foo "
        fi
        run_depends+="${_depname} "
    done

    [[ $out && $_deps ]] && echo "$_deps"
    return 0
}

#
# Install required package dependencies, like:
#
#	xbps-install -AIy <pkgs>
#
#       -A automatic mode
#       -I to ignore file conflicts
#       -y yes
#
# Returns 0 if package already installed or installed successfully.
# Any other error number otherwise.
#
# SUCCESS  (0): package installed successfully.
# ENOENT   (2): package missing in repositories.
# ENXIO    (6): package depends on invalid dependencies.
# EAGAIN  (11): package conflicts.
# EEXIST  (17): file conflicts in transaction (XBPS_FLAG_IGNORE_FILE_CONFLICTS unset)
# ENODEV  (19): package depends on missing dependencies.
# ENOTSUP (95): no repositories registered.
#
install_pkg_from_repos() {
    local cross="$1" rval tmplogf cmd
    shift

    [ $# -eq 0 ] && return 0

    mkdir -p $XBPS_STATEDIR
    tmplogf=${XBPS_STATEDIR}/xbps_${XBPS_TARGET_MACHINE}_bdep_${pkg}.log

    cmd=$XBPS_INSTALL_CMD
    [[ $cross ]] && cmd=$XBPS_INSTALL_XCMD
    $cmd ${XBPS_SKIP_REMOTEREPOS:+-i} -AIy "$@" >$tmplogf 2>&1
    rval=$?

    case "$rval" in
        0) # success, check if there are errors.
           errortmpf=$(mktemp) || exit 1
           grep ^ERROR $tmplogf > $errortmpf
           [ -s $errortmpf ] && cat $errortmpf
           rm -f $errortmpf
           ;;
        *)
           [ -z "$XBPS_KEEP_ALL" ] && remove_pkg_autodeps
           msg_red "$pkgver: failed to install '$1' dependency! (error $rval)\n"
           cat $tmplogf
           rm -f $tmplogf
           msg_error "Please see above for the real error, exiting...\n"
           ;;
    esac
    rm -f $tmplogf
    return $rval
}

#
# Returns 0 if pkgpattern in $1 is installed and greater than current
# installed package, otherwise 1.
#
check_installed_pkg() {
    local pkg="$1" cross="$2" uhelper= pkgn= iver=

    [ -z "$pkg" ] && return 2

    pkgn="$($XBPS_UHELPER_CMD getpkgname ${pkg})"
    [ -z "$pkgn" ] && return 2

    uhelper=$XBPS_UHELPER_CMD
    [[ $cross ]] && uhelper=$XBPS_UHELPER_XCMD
    iver="$($uhelper version $pkgn)"
    if [ $? -eq 0 -a -n "$iver" ]; then
        $XBPS_CMPVER_CMD "${pkgn}-${iver}" "${pkg}"
        [ $? -eq 0 -o $? -eq 1 ] && return 0
    fi

    return 1
}

#
# Build all dependencies required to build and run.
#
install_pkg_deps() {
    local pkg="$1" targetpkg="$2" target="$3" cross="$4" cross_prepare="$5"
    local _vpkg curpkgdepname
    local i j found style

    local -a host_binpkg_deps binpkg_deps
    local -a host_missing_deps missing_deps missing_rdeps

    [ -z "$pkgname" ] && return 2
    [ -z "$XBPS_CHECK_PKGS" ] && unset checkdepends
    [[ $build_style ]] && style=" [$build_style]"

    for s in $build_helper; do
        style+=" [$s]"
    done

    if [ "$pkg" != "$targetpkg" ]; then
        msg_normal "$pkgver: building${style} (dependency of $targetpkg) ...\n"
    else
        msg_normal "$pkgver: building${style} ...\n"
    fi

    #
    # Host build dependencies.
    #
    if [[ ${hostmakedepends} ]]; then
        # check validity
        for f in ${hostmakedepends}; do
            if [ ! -f $XBPS_SRCPKGDIR/$f/template ]; then
                msg_error "$pkgver: host dependency '$f' does not exist!\n"
            fi
        done
        while read -r _depname _deprepover _depver _subpkg _repourl; do
            _vpkg=${_subpkg}-${_depver}
            # binary package found in a repo
            if [[ ${_depver} == ${_deprepover} ]]; then
                echo "   [host] ${_vpkg}: found (${_repourl})"
                host_binpkg_deps+=("${_vpkg}")
                continue
            fi
            # binary package not found
            if [[ $_depname != $_subpkg ]]; then
                # subpkg, check if it's a subpkg of itself
                found=0
                for f in ${subpackages}; do
                    if [[ ${_subpkg} == ${f} ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 1 ]]; then
                    echo "   [host] ${_vpkg}: not found (subpkg, ignored)"
                else
                    echo "   [host] ${_vpkg}: not found"
                    host_missing_deps+=("$_vpkg")
                fi
            else
                echo "   [host] ${_vpkg}: not found"
                host_missing_deps+=("$_vpkg")
            fi
        done < <($XBPS_CHECKVERS_CMD ${XBPS_SKIP_REMOTEREPOS:+-i} -D $XBPS_DISTDIR -sm ${hostmakedepends})
    fi

    #
    # Host check dependencies.
    #
    if [[ ${checkdepends} ]] && [[ $XBPS_CHECK_PKGS ]]; then
        # check validity
        for f in ${checkdepends}; do
            if [ ! -f $XBPS_SRCPKGDIR/$f/template ]; then
                msg_error "$pkgver: check dependency '$f' does not exist!\n"
            fi
        done
        while read -r _depname _deprepover _depver _subpkg _repourl; do
            _vpkg=${_subpkg}-${_depver}
            # binary package found in a repo
            if [[ ${_depver} == ${_deprepover} ]]; then
                echo "   [check] ${_vpkg}: found (${_repourl})"
                host_binpkg_deps+=("${_vpkg}")
                continue
            fi
            # binary package not found
            if [[ $_depname != $_subpkg ]]; then
                # subpkg, check if it's a subpkg of itself
                found=0
                for f in ${subpackages}; do
                    if [[ ${_subpkg} == ${f} ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 1 ]]; then
                    echo "   [check] ${_vpkg}: not found (subpkg, ignored)"
                else
                    echo "   [check] ${_vpkg}: not found"
                    host_missing_deps+=("$_vpkg")
                fi
            else
                echo "   [check] ${_vpkg}: not found"
                host_missing_deps+=("$_vpkg")
            fi
        done < <($XBPS_CHECKVERS_CMD ${XBPS_SKIP_REMOTEREPOS:+-i} -D $XBPS_DISTDIR -sm ${checkdepends})
    fi

    #
    # Target build dependencies.
    #
    if [[ ${makedepends} ]]; then
        # check validity
        for f in ${makedepends}; do
            if [ ! -f $XBPS_SRCPKGDIR/$f/template ]; then
                msg_error "$pkgver: target dependency '$f' does not exist!\n"
            fi
        done
        while read -r _depname _deprepover _depver _subpkg _repourl; do
            _vpkg=${_subpkg}-${_depver}
            # binary package found in a repo
            if [[ ${_depver} == ${_deprepover} ]]; then
                echo "   [target] ${_vpkg}: found (${_repourl})"
                binpkg_deps+=("${_vpkg}")
                continue
            fi
            # binary package not found
            if [[ $_depname != $_subpkg ]]; then
                # subpkg, check if it's a subpkg of itself
                found=0
                for f in ${subpackages}; do
                    if [[ ${_subpkg} == ${f} ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 1 ]]; then
                    echo "   [target] ${_vpkg}: not found (subpkg, ignored)"
                else
                    echo "   [target] ${_vpkg}: not found"
                    missing_deps+=("$_vpkg")
                fi
            else
                echo "   [target] ${_vpkg}: not found"
                missing_deps+=("$_vpkg")
            fi
        done < <($XBPS_CHECKVERS_XCMD ${XBPS_SKIP_REMOTEREPOS:+-i} -D $XBPS_DISTDIR -sm ${makedepends})
    fi

    #
    # Target run time dependencies
    #
    if [[ ${depends} ]]; then
        _deps=$(setup_pkg_depends "" 1) || exit 1
        for f in ${_deps}; do
            if [ ! -f $XBPS_SRCPKGDIR/$f/template ]; then
                msg_error "$pkgver: runtime dependency '$f' does not exist!\n"
            fi
        done
        while read -r _depname _deprepover _depver _subpkg _repourl; do
            _vpkg=${_subpkg}-${_depver}
            # binary package found in a repo
            if [[ ${_depver} == ${_deprepover} ]]; then
                echo "   [runtime] ${_vpkg}: found (${_repourl})"
                continue
            fi
            # binary package not found
            if [[ $_depname != $_subpkg ]]; then
                # subpkg, check if it's a subpkg of itself
                found=0
                for f in ${subpackages}; do
                    if [[ ${_subpkg} == ${f} ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 1 ]]; then
                    echo "   [runtime] ${_vpkg}: not found (subpkg, ignored)"
                else
                    echo "   [runtime] ${_vpkg}: not found"
                    missing_rdeps+=("$_vpkg")
                fi
            else
                echo "   [runtime] ${_vpkg}: not found"
                missing_rdeps+=("$_vpkg")
            fi
        done < <($XBPS_CHECKVERS_XCMD ${XBPS_SKIP_REMOTEREPOS:+-i} -D $XBPS_DISTDIR -sm $_deps)
        unset _deps
    fi

    if [ -n "$XBPS_BUILD_ONLY_ONE_PKG" ]; then
           for i in ${host_missing_deps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
           for i in ${missing_rdeps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
           for i in ${missing_deps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
    fi

    # Missing host dependencies, build from srcpkgs.
    for i in ${host_missing_deps[@]}; do
        # packages not found in repos, install from source.
        (
        curpkgdepname=$($XBPS_UHELPER_CMD getpkgname "$i" 2>/dev/null)
        setup_pkg $curpkgdepname
        exec env XBPS_DEPENDENCY=1 XBPS_BINPKG_EXISTS=1 \
            $XBPS_LIBEXECDIR/build.sh $sourcepkg $pkg $target || exit $?
        ) || exit $?
        host_binpkg_deps+=("$i")
    done

    # Missing target dependencies, build from srcpkgs.
    for i in ${missing_deps[@]}; do
        # packages not found in repos, install from source.
        (

        curpkgdepname=$($XBPS_UHELPER_CMD getpkgname "$i" 2>/dev/null)
        setup_pkg $curpkgdepname $cross
        exec env XBPS_DEPENDENCY=1 XBPS_BINPKG_EXISTS=1 \
            $XBPS_LIBEXECDIR/build.sh $sourcepkg $pkg $target $cross $cross_prepare || exit $?
        ) || exit $?
        binpkg_deps+=("$i")
    done

    # Target runtime missing dependencies, build from srcpkgs.
    for i in ${missing_rdeps[@]}; do
        # packages not found in repos, install from source.
        (
        curpkgdepname=$($XBPS_UHELPER_CMD getpkgdepname "$i" 2>/dev/null)
        if [ -z "$curpkgdepname" ]; then
            curpkgdepname=$($XBPS_UHELPER_CMD getpkgname "$i" 2>/dev/null)
            if [ -z "$curpkgdepname" ]; then
                curpkgdepname="$i"
            fi
        fi
        setup_pkg $curpkgdepname $cross
        exec env XBPS_DEPENDENCY=1 XBPS_BINPKG_EXISTS=1 \
            $XBPS_LIBEXECDIR/build.sh $sourcepkg $pkg $target $cross $cross_prepare || exit $?
        ) || exit $?
    done

    if [[ ${host_binpkg_deps} ]]; then
        if [ -z "$XBPS_QUIET" ]; then
            # normal messages in bold
            [[ $NOCOLORS ]] || printf "\033[1m"
            echo "=> $pkgver: installing host dependencies: ${host_binpkg_deps[@]} ..."
            [[ $NOCOLORS ]] || printf "\033[m"
        fi
        install_pkg_from_repos "" "${host_binpkg_deps[@]}"
    fi

    if [[ ${binpkg_deps} ]]; then
        if [ -z "$XBPS_QUIET" ]; then
            # normal messages in bold
            [[ $NOCOLORS ]] || printf "\033[1m"
            echo "=> $pkgver: installing target dependencies: ${binpkg_deps[@]} ..."
            [[ $NOCOLORS ]] || printf "\033[m"
        fi
        install_pkg_from_repos "$cross" "${binpkg_deps[@]}"
    fi

    return 0
}
