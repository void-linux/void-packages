# vim: set ts=4 sw=4 et:

show_pkg() {
    local i=

    echo "pkgname:	$pkgname"
    echo "version:	$version"
    echo "revision:	$revision"
    for i in ${distfiles}; do
        [ -n "$i" ] && echo "distfiles:	$i"
    done
    for i in ${checksum}; do
        [ -n "$i" ] && echo "checksum:	$i"
    done
    [ -n "$noarch" ] && echo "noarch:		yes"
    echo "maintainer:	$maintainer"
    [ -n "$homepage" ] && echo "Upstream URL:	$homepage"
    [ -n "$license" ] && echo "License(s):	$license"
    [ -n "$build_style" ] && echo "build_style:	$build_style"
    for i in ${configure_args}; do
        [ -n "$i" ] && echo "configure_args:	$i"
    done
    echo "short_desc:	$short_desc"
    for i in ${subpackages}; do
        [ -n "$i" ] && echo "subpackages:	$i"
    done
    set -f
    for i in ${conf_files}; do
        [ -n "$i" ] && echo "conf_files:	$i"
    done
    set +f
    for i in ${replaces}; do
        [ -n "$i" ] && echo "replaces:	$i"
    done
    for i in ${provides}; do
        [ -n "$i" ] && echo "provides:	$i"
    done
    for i in ${conflicts}; do
        [ -n "$i" ] && echo "conflicts:	$i"
    done
    [ -n "$long_desc" ] && echo "long_desc: $long_desc"

    return 0
}

show_pkg_deps() {
    [ -f "${PKGDESTDIR}/rdeps" ] && cat ${PKGDESTDIR}/rdeps
}

show_pkg_files() {
    [ -d ${PKGDESTDIR} ] && find ${PKGDESTDIR} -print
}

show_avail() {
    check_pkg_arch "$XBPS_CROSS_BUILD" 2>/dev/null
}

show_pkg_build_deps() {
    local f x _pkgname _srcpkg _dep found result

    setup_pkg_depends

    result=$(mktemp || exit 1)

    # build time deps
    for f in ${host_build_depends} ${build_depends} ${run_depends}; do
        # ignore virtual deps
        local _rpkg="${f%\?*}"
        local _vpkg="${f#*\?}"

        # ignore virtual dependencies
        if [ "${_rpkg}" != "${_vpkg}" ]; then
            f="${_vpkg}"
        fi
        unset found
        # check for subpkgs
        for x in ${subpackages}; do
            _pkgname="$($XBPS_UHELPER_CMD getpkgdepname $f 2>/dev/null)"
            if [ -z "${_pkgname}" ]; then
                _pkgname="$($XBPS_UHELPER_CMD getpkgname $f 2>/dev/null)"
            fi
            if [ "${_pkgname}" = "$x" ]; then
                found=1
                break
            fi
        done
        if [ -n "$found" ]; then
            continue
        fi
        _pkgname="$($XBPS_UHELPER_CMD getpkgdepname $f 2>/dev/null)"
        if [ -z "${_pkgname}" ]; then
            _pkgname="$($XBPS_UHELPER_CMD getpkgname $f 2>/dev/null)"
        fi
        if [ -z "${_pkgname}" ]; then
            _pkgname="$f"
        fi
        _pkgname=${_pkgname/-32bit}
        _srcpkg=$(basename $(readlink -f ${XBPS_SRCPKGDIR}/${_pkgname}))
        echo "${_srcpkg}" >> $result
    done
    sort -u $result
    rm -f $result
}


show_pkg_build_options() {
    local f opt desc

    [ -z "$PKG_BUILD_OPTIONS" ] && return 0

    source $XBPS_COMMONDIR/options.description
    msg_normal "$pkgver: the following build options are set:\n"
    for f in ${PKG_BUILD_OPTIONS}; do
        opt="${f#\~}"
        eval desc="\${desc_option_${opt}}"
        if [[ ${f:0:1} == '~' ]]; then
            echo "   $opt: $desc (OFF)"
        else
            printf "   "
            msg_normal_append "$opt: "
            printf "$desc (ON)\n"
        fi
    done
}

show_pkg_shlib_provides() {
    [ -f "${PKGDESTDIR}/shlib-provides" ] && cat ${PKGDESTDIR}/shlib-provides
}

show_pkg_shlib_requires() {
    [ -f "${PKGDESTDIR}/shlib-requires" ] && cat ${PKGDESTDIR}/shlib-requires
}
