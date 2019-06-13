# vim: set ts=4 sw=4 et:
#

setup_pkg_depends() {
    local pkg="$1" j _pkgdepname _pkgdep _rpkgname _depname _deprepover _depver _replacement

    if [ -n "$pkg" ]; then
        # subpkg
        if declare -f ${pkg}_package >/dev/null; then
            ${pkg}_package
        fi
    fi

    for j in ${depends}; do
        _rpkgname="${j%\?*}"
        _depname="${j#*\?}"
        _pkgdepname="$($XBPS_UHELPER_CMD getpkgdepname ${_depname} 2>/dev/null)"
        if [ -z "${_pkgdepname}" ]; then
            _pkgdepname="$($XBPS_UHELPER_CMD getpkgname ${_depname} 2>/dev/null)"
        fi
        if [ -s ${XBPS_DISTDIR}/etc/virtual ]; then
            _replacement=$(egrep "^${_pkgdepname:-${_depname}}[[:blank:]]" ${XBPS_DISTDIR}/etc/virtual|cut -d ' ' -f2)
        elif [ -s ${XBPS_DISTDIR}/etc/defaults.virtual ]; then
            _replacement=$(egrep "^${_pkgdepname:-${_depname}}[[:blank:]]" ${XBPS_DISTDIR}/etc/defaults.virtual|cut -d ' ' -f2)
        fi
        if [ "${_rpkgname}" = "virtual" ]; then
            if [ -z "${_replacement}" ]; then
                msg_error "$pkgver: failed to resolve virtual dependency for '$j' (missing from etc/virtual)\n"
            fi
            _pkgdepname="$($XBPS_UHELPER_CMD getpkgdepname ${_replacement} 2>/dev/null)"
            if [ -z "${_pkgdepname}" ]; then
                _pkgdepname="$($XBPS_UHELPER_CMD getpkgname ${_replacement} 2>/dev/null)"
            fi
            if [ -z "${_pkgdepname}" ]; then
                _pkgdepname="${_replacement}>=0"
            fi
            # run_depends+=" ${_depname}?${_pkgdepname}"
            run_depends+=" ${_pkgdepname}"
            #echo "Adding dependency virtual:  ${_depname}?${_pkgdepname}"
        else
            if [ -z "${_pkgdepname}" ]; then
                _pkgdep="${_depname}>=0"
            else
                _pkgdep="${_depname}"
            fi
            run_depends+=" ${_pkgdep}"
        fi
    done

}

# Install a required package dependency, like:
#
#	xbps-install -Ay <pkgname>
#
# Returns 0 if package already installed or installed successfully.
# Any other error number otherwise.
#
install_pkg_from_repos() {
    local pkg="$1" cross="$2" rval= tmplogf=

    mkdir -p $XBPS_STATEDIR
    tmplogf=${XBPS_STATEDIR}/xbps_${XBPS_TARGET_MACHINE}_bdep_${pkg}.log

    if [ -n "$cross" ]; then
        $XBPS_INSTALL_XCMD -Ayd "$pkg" >$tmplogf 2>&1
    else
        $XBPS_INSTALL_CMD -Ayd "$pkg" >$tmplogf 2>&1
    fi
    rval=$?
    if [ $rval -ne 0 -a $rval -ne 17 ]; then
        # xbps-install can return:
        #
        # SUCCESS  (0): package installed successfully.
        # ENOENT   (2): package missing in repositories.
        # ENXIO    (6): package depends on invalid dependencies.
        # EAGAIN  (11): package conflicts.
        # EEXIST  (17): package already installed.
        # ENODEV  (19): package depends on missing dependencies.
        # ENOTSUP (95): no repositories registered.
        #
        [ -z "$XBPS_KEEP_ALL" ] && remove_pkg_autodeps
        msg_red "$pkgver: failed to install '$1' dependency! (error $rval)\n"
        cat $tmplogf
        msg_error "Please see above for the real error, exiting...\n"
    fi
    [ $rval -eq 17 ] && rval=0
    return $rval
}

install_pkgs_from_repos() {
    local cross="$1" rval= tmplogf=
    shift 1

    [ $# -eq 0 ] && return 0

    mkdir -p $XBPS_STATEDIR
    tmplogf=${XBPS_STATEDIR}/xbps_${XBPS_TARGET_MACHINE}_bdep.log

    if [ -n "$cross" ]; then
        $XBPS_INSTALL_XCMD -Ayd "$@" >$tmplogf 2>&1
    else
        $XBPS_INSTALL_CMD -Ayd "$@" >$tmplogf 2>&1
    fi
    rval=$?
    if [ $rval -ne 0 -a $rval -ne 17 ]; then
        # xbps-install can return:
        #
        # SUCCESS  (0): package installed successfully.
        # ENOENT   (2): package missing in repositories.
        # ENXIO    (6): package depends on invalid dependencies.
        # EAGAIN  (11): package conflicts.
        # EEXIST  (17): package already installed.
        # ENODEV  (19): package depends on missing dependencies.
        # ENOTSUP (95): no repositories registered.
        #
        [ -z "$XBPS_KEEP_ALL" ] && remove_pkg_autodeps
        # msg_red "$pkgver: failed to install '$1' dependency! (error $rval)\n"
        cat $tmplogf
        msg_error "Please see above for the real error, exiting...\n"
    fi
    [ $rval -eq 17 ] && rval=0
    return $rval
}


#
# Returns 0 if pkgpattern in $1 is matched against current installed
# package, 1 if no match and 2 if not installed.
#
check_pkgdep_matched() {
    local pkg="$1" checkver="$2" cross="$3" uhelper= pkgn= iver=

    [ "$build_style" = "meta" ] && return 2
    [ -z "$pkg" ] && return 255

    pkgn="$($XBPS_UHELPER_CMD getpkgdepname ${pkg} 2>/dev/null)"
    if [ -z "$pkgn" ]; then
        pkgn="$($XBPS_UHELPER_CMD getpkgname ${pkg} 2>/dev/null)"
    fi
    [ -z "$pkgn" ] && return 255

    if [ -n "$cross" ]; then
        uhelper="$XBPS_UHELPER_XCMD"
    else
        uhelper="$XBPS_UHELPER_CMD"
    fi

    iver="$($uhelper $checkver $pkgn)"
    if [ $? -eq 0 -a -n "$iver" ]; then
        $XBPS_UHELPER_CMD pkgmatch "${pkgn}-${iver}" "${pkg}"
        [ $? -eq 1 ] && return 0
    else
        return 2
    fi

    return 1
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

    if [ -n "$cross" ]; then
        uhelper="$XBPS_UHELPER_XCMD"
    else
        uhelper="$XBPS_UHELPER_CMD"
    fi

    iver="$($uhelper version $pkgn)"
    if [ $? -eq 0 -a -n "$iver" ]; then
        $XBPS_CMPVER_CMD "${pkgn}-${iver}" "${pkg}"
        [ $? -eq 0 -o $? -eq 1 ] && return 0
    fi

    return 1
}

srcpkg_get_version() {
    local pkg="$1"
    # Run this in a sub-shell to avoid polluting our env.
    (
    unset XBPS_BINPKG_EXISTS
    setup_pkg $pkg || exit $?
    echo "${version}_${revision}"
    ) || msg_error "$pkgver: failed to transform dependency $pkg\n"
}

srcpkg_get_pkgver() {
    local pkg="$1"
    # Run this in a sub-shell to avoid polluting our env.
    (
    unset XBPS_BINPKG_EXISTS
    setup_pkg $pkg || exit $?
    echo "${sourcepkg}-${version}_${revision}"
    ) || msg_error "$pkgver: failed to transform dependency $pkg\n"
}

#
# Installs all dependencies required by a package.
#
install_pkg_deps() {
    local pkg="$1" targetpkg="$2" target="$3" cross="$4" cross_prepare="$5"
    local rval _realpkg _vpkg _curpkg curpkgdepname pkgn iver
    local i j found rundep repo style

    local -a host_binpkg_deps check_binpkg_deps binpkg_deps
    local -a host_missing_deps check_missing_deps missing_deps missing_rdeps

    [ -z "$pkgname" ] && return 2

    setup_pkg_depends

    
    [ -n "$build_style" ] && style=" [$build_style]"

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
    if [ -n "${hostdepends}" ]; then
        local -a _hostdepends
        for i in ${hostdepends}; do
            _hostdepends+=("$i")
        done
        i=0
        while read -r _depname _deprepover _depver; do
            _depname=${_hostdepends[$(( i++ ))]}
            if [ "$_depver" != "$_deprepover" ]; then
                host_missing_deps+=("${_depname}-${_depver}")
            else
                host_binpkg_deps+=" ${_depname}-${_depver}"
            fi
            host_build_depends+=" ${_depname}-${_depver}"
        done < <(xbps-checkvers -D /void-packages -sm $(printf "srcpkgs/%s/template\n" ${hostmakedepends}))
    fi

    #
    # Host check dependencies.
    #
    if [ -n "$XBPS_CHECK_PKGS" -a -n "${checkdepends}" ]; then
        local -a _checkdepends
        for i in ${checkdepends}; do
            _checkdepends+=("$i")
        done
        i=0
        while read -r _depname _deprepover _depver; do
            _depname=${_checkdepends[$(( i++ ))]}
            if [ "$_depver" != "$_deprepover" ]; then
                host_missing_deps+=("${_depname}-${_depver}")
            else
                host_binpkg_deps+=" ${_depname}-${_depver}"
            fi
            host_check_depends+=" ${_depname}-${_depver}"
        done < <(xbps-checkvers -D /void-packages -sm $(printf "srcpkgs/%s/template\n" ${hostcheckdepends}))
    fi

    #
    # Target build dependencies.
    #
    if [ -n "${makedepends}" ]; then
        local -a _makedepends
        for i in ${makedepends}; do
            _makedepends+=("$i")
        done
        i=0
        while read -r _depname _deprepover _depver; do
            _depname=${_makedepends[$(( i++ ))]}
            if [ "$_depver" != "$_deprepover" ]; then
                missing_deps+=("${_depname}-${_depver}")
            else
                binpkg_deps+=" ${_depname}-${_depver}"
            fi
            build_depends+=" ${_depname}-${_depver}"
        done < <(xbps-checkvers -D /void-packages -sm $(printf "srcpkgs/%s/template\n" ${makedepends}))
    fi


    #
    # Target run time dependencies
    #
    if [ -n "${depends}" ]; then
        local -a _depends
        for i in ${depends}; do
            _depends+=("$i")
        done
        i=0
        while read -r _depname _deprepover _depver; do
            _depname=${_depends[$(( i++ ))]}
            if [ "$_depver" != "$_deprepover" ]; then
                missing_deps+=("${_depname}-${_depver}")
            fi
            build_depends+=" ${_depname}-${_depver}"
        done < <(xbps-checkvers -D /void-packages -sm $(printf "srcpkgs/%s/template\n" ${run_depends}))
    fi

    if [ -n "$XBPS_BUILD_ONLY_ONE_PKG" ]; then
           for i in ${host_missing_deps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
           for i in ${check_missing_deps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
           for i in ${missing_rdeps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
           for i in ${missing_deps[@]}; do
                   msg_error "dep ${i} not found: -1 passed: instructed not to build\n"
           done
    fi

    if [ -z "$build_depends" -a -z "$host_build_depends" -a -z "$host_check_depends" -a -z "$run_depends" ]; then
        return 0
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

    # Missing check dependencies, build from srcpkgs.
    for i in ${check_missing_deps[@]}; do
        # packages not found in repos, install from source.
        (
        curpkgdepname=$($XBPS_UHELPER_CMD getpkgname "$i" 2>/dev/null)
        setup_pkg $curpkgdepname
        exec env XBPS_DEPENDENCY=1 XBPS_BINPKG_EXISTS=1 \
            $XBPS_LIBEXECDIR/build.sh $sourcepkg $pkg $target || exit $?
        ) || exit $?
        check_binpkg_deps+=("$i")
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

    if [ "$pkg" != "$targetpkg" ]; then
        msg_normal "$pkg: building${style} (dependency of $targetpkg) ...\n"
    fi

    for i in ${host_binpkg_deps[@]}; do
        msg_normal "$pkgver: installing host dependency '$i' ...\n"
    done
    for i in ${check_binpkg_deps[@]}; do
        msg_normal "$pkgver: installing check dependency '$i' ...\n"
    done
    install_pkgs_from_repos "" ${host_binpkg_deps[@]} ${check_binpkg_deps[@]}


    for i in ${binpkg_deps[@]}; do
        msg_normal "$pkgver: installing target dependency '$i' ...\n"
    done
    install_pkgs_from_repos "$cross" ${binpkg_deps[@]}
}
