# vim: set ts=4 sw=4 et:
#
setup_pkg_depends() {
    local pkg="$1" j _pkgdepname _pkgdep _rpkgname _depname _depver _replacement

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
            run_depends+=" ${_depname}?${_pkgdepname}"
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
    for j in ${hostmakedepends}; do
        _depname="${j%\?*}"
        _depver=$(srcpkg_get_version ${_depname}) || exit $?
        host_build_depends+=" ${_depname}-${_depver}"
    done
    if [ -n "$XBPS_CHECK_PKGS" ]; then
        for j in ${checkdepends}; do
            _depname="${j%\?*}"
            _depver=$(srcpkg_get_version ${_depname}) || exit $?
            host_check_depends+=" ${_depname}-${_depver}"
        done
    fi
    for j in ${makedepends}; do
        _depname="${j%\?*}"
        _depver=$(srcpkg_get_version ${_depname}) || exit $?
        build_depends+=" ${_depname}-${_depver}"
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
    local i j found rundep repo

    local -a host_binpkg_deps check_binpkg_deps binpkg_deps
    local -a host_missing_deps check_missing_deps missing_deps missing_rdeps

    [ -z "$pkgname" ] && return 2

    setup_pkg_depends

    if [ "$pkg" != "$targetpkg" ]; then
        msg_normal "$pkgver: building (dependency of $targetpkg) ...\n"
    else
        msg_normal "$pkgver: building ...\n"
    fi

    if [ -z "$build_depends" -a -z "$host_build_depends" -a -z "$host_check_depends" -a -z "$run_depends" ]; then
        return 0
    fi

    #
    # Host build dependencies.
    #
    for i in ${host_build_depends}; do
        check_pkgdep_matched "$i" version
        local rval=$?
        if [ $rval -eq 0 ]; then
            echo "   [host] ${i}: installed."
            continue
        elif [ $rval -eq 1 ]; then
            _realpkg="$($XBPS_UHELPER_CMD getpkgname $i 2>/dev/null)"
            iver=$($XBPS_UHELPER_CMD version ${_realpkg})
            if [ $? -eq 0 -a -n "$iver" ]; then
                echo "   [host] ${i}: installed $iver (virtualpkg)."
                continue
            else
                echo "   [host] ${i}: unresolved build dependency!"
                return 1
            fi
        else
            repo=$($XBPS_QUERY_CMD -R -prepository ${i} 2>/dev/null)
            if [ -n "${repo}" ]; then
                echo "   [host] ${i}: found ($repo)"
                host_binpkg_deps+=("${i}")
                continue
            else
                echo "   [host] ${i}: not found."
            fi
        fi
        host_missing_deps+=("${i}")
    done

    #
    # Host check dependencies.
    #
    for i in ${host_check_depends}; do
        check_pkgdep_matched "$i" version
        local rval=$?
        if [ $rval -eq 0 ]; then
            echo "   [check] ${i}: installed."
            continue
        elif [ $rval -eq 1 ]; then
            _realpkg="$($XBPS_UHELPER_CMD getpkgname $i 2>/dev/null)"
            iver=$($XBPS_UHELPER_CMD version ${_realpkg})
            if [ $? -eq 0 -a -n "$iver" ]; then
                echo "   [check] ${i}: installed $iver (virtualpkg)."
                continue
            else
                echo "   [check] ${i}: unresolved check dependency!"
                return 1
            fi
        else
            repo=$($XBPS_QUERY_CMD -R -prepository ${i} 2>/dev/null)
            if [ -n "${repo}" ]; then
                echo "   [check] ${i}: found ($repo)"
                check_binpkg_deps+=("${i}")
                continue
            else
                echo "   [check] ${i}: not found."
            fi
        fi
        check_missing_deps+=("${i}")
    done


    #
    # Target build dependencies.
    #
    for i in ${build_depends}; do
        _realpkg="$($XBPS_UHELPER_CMD getpkgname $i 2>/dev/null)"
        # Check if dependency is a subpkg, if it is, ignore it.
        unset found
        for j in ${subpackages}; do
            [ "$j" = "${_realpkg}" ] && found=1 && break
        done
        [ -n "$found" ] && continue
        check_pkgdep_matched "${i}" version $cross
        local rval=$?
        if [ $rval -eq 0 ]; then
            echo "   [target] ${i}: installed."
            continue
        elif [ $rval -eq 1 ]; then
            iver=$($XBPS_UHELPER_XCMD version ${_realpkg})
            if [ $? -eq 0 -a -n "$iver" ]; then
                echo "   [target] ${i}: installed $iver (virtualpkg)."
                continue
            else
                echo "   [target] ${i}: unresolved build dependency!"
                return 1
            fi
        else
            repo=$($XBPS_QUERY_XCMD -R -prepository ${i} 2>/dev/null)
            if [ -n "${repo}" ]; then
                echo "   [target] ${i}: found ($repo)"
                binpkg_deps+=("${i}")
                continue
            else
                echo "   [target] ${i}: not found."
            fi
        fi
        missing_deps+=("${i}")
    done

    #
    # Target run time dependencies
    #
    for i in ${run_depends}; do
        _realpkg="${i%\?*}"
        _curpkg="${_realpkg}"
        _vpkg="${i#*\?}"
        if [ "${_realpkg}" != "${_vpkg}" ]; then
            _realpkg="${_vpkg}"
        else
            unset _curpkg
        fi
        pkgn=$($XBPS_UHELPER_CMD getpkgdepname "${_realpkg}")
        if [ -z "$pkgn" ]; then
            pkgn=$($XBPS_UHELPER_CMD getpkgname "${_realpkg}")
            if [ -z "$pkgn" ]; then
                msg_error "$pkgver: invalid runtime dependency: ${_realpkg}\n"
            fi
        fi
        # Check if dependency is a subpkg, if it is, ignore it.
        unset found
        for j in ${subpackages}; do
            [ "$j" = "${pkgn}" ] && found=1 && break
        done
        [ -n "$found" ] && continue
        _props=$($XBPS_QUERY_XCMD -R -ppkgver,repository ${_realpkg} 2>/dev/null)
        if [ -n "${_props}" ]; then
            set -- ${_props}
            $XBPS_UHELPER_CMD pkgmatch ${1} "${_realpkg}"
            if [ $? -eq 1 ]; then
                if [ -n "${_curpkg}" ]; then
                    echo "   [runtime] ${_curpkg}:${_realpkg} (virtual dependency): found $1 ($2)"
                else
                    echo "   [runtime] ${_realpkg}: found $1 ($2)"
                fi
                shift 2
                continue
            else
                if [ -n "${_curpkg}" ]; then
                    echo "   [runtime] ${_curpkg}:${_realpkg} (virtual dependency): not found."
                else
                    echo "   [runtime] ${_realpkg}: not found."
                fi
            fi
            shift 2
        else
            if [ -n "${_curpkg}" ]; then
                echo "   [runtime] ${_curpkg}:${_realpkg} (virtual dependency): not found."
            else
                echo "   [runtime] ${_realpkg}: not found."
            fi
        fi
        missing_rdeps+=("${_realpkg}")
    done

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
        msg_normal "$pkg: building (dependency of $targetpkg) ...\n"
    fi

    for i in ${host_binpkg_deps[@]}; do
        msg_normal "$pkgver: installing host dependency '$i' ...\n"
        install_pkg_from_repos "${i}"
    done

    for i in ${check_binpkg_deps[@]}; do
        msg_normal "$pkgver: installing check dependency '$i' ...\n"
        install_pkg_from_repos "${i}"
    done

    for i in ${binpkg_deps[@]}; do
        msg_normal "$pkgver: installing target dependency '$i' ...\n"
        install_pkg_from_repos "$i" $cross
    done
}
