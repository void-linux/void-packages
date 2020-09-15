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
    for i in ${archs}; do
        [ -n "$i" ] && echo "archs:		$i"
    done
    echo "maintainer:	$maintainer"
    [ -n "$homepage" ] && echo "Upstream URL:	$homepage"
    [ -n "$license" ] && echo "License(s):	$license"
    [ -n "$changelog" ] && echo "Changelog:	$changelog"
    [ -n "$build_style" ] && echo "build_style:	$build_style"
    for i in $build_helper; do
        [ -n "$i" ] && echo "build_helper:  $i"
    done
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
    local OIFS="$IFS"
    IFS=','
    for var in $1; do
        IFS=$OIFS
        if [ ${var} != ${var/'*'} ]
        then
            var="${var/'*'}"
            [ -n "${!var}" ] && echo "$var:	${!var//$'\n'/' '}"
        else
            for val in ${!var}; do
                [ -n "$val" ] && echo "$var:	$val"
            done
        fi
    done
    IFS="$OIFS"
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

show_pkg_build_depends() {
    local f x _pkgname _srcpkg found result
    local _deps="$1"

    result=$(mktemp) || exit 1

    # build time deps
    for f in ${_deps}; do
        if [ -z "$CROSS_BUILD" ]; then
            # ignore dependency on itself
            [[ $f == $sourcepkg ]] && continue
        fi
        if [ ! -f $XBPS_SRCPKGDIR/$f/template ]; then
            msg_error "$pkgver: dependency '$f' does not exist!\n"
        fi
        # ignore virtual dependencies
        [[ ${f%\?*} != ${f#*\?} ]] && f=${f#*\?}
        unset found
        # check for subpkgs
        for x in ${subpackages}; do
            [[ $f == $x ]] && found=1 && break
        done
        [[ $found ]] && continue
        _pkgname=${f/-32bit}
        _srcpkg=$(readlink -f ${XBPS_SRCPKGDIR}/${_pkgname})
        _srcpkg=${_srcpkg##*/}
        echo "${_srcpkg}" >> $result
    done
    sort -u $result
    rm -f $result
}

show_pkg_build_deps() {
    show_pkg_build_depends "${hostmakedepends} ${makedepends} $(setup_pkg_depends '' 1 1)"
}

show_pkg_hostmakedepends() {
    show_pkg_build_depends "${hostmakedepends}"
}

show_pkg_makedepends() {
    show_pkg_build_depends "${makedepends}"
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
