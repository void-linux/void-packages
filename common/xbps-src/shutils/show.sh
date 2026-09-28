# vim: set ts=4 sw=4 et:

show_pkg() {
    show_pkg_var "pkgname" "$pkgname"
    show_pkg_var "version" "$version"
    show_pkg_var "revision" "$revision"
    show_pkg_var "distfiles" "$distfiles" 1
    show_pkg_var "checksum" "$checksum" 1
    show_pkg_var "archs" "$archs" 1
    show_pkg_var "maintainer" "${maintainer}"
    show_pkg_var "Upstream URL" "$homepage"
    show_pkg_var "License(s)" "${license//,/ }" 1
    show_pkg_var "Changelog" "$changelog"
    show_pkg_var "build_style" "$build_style"
    show_pkg_var "build_helper" "$build_helper" 1
    show_pkg_var "configure_args" "$configure_args" 1
    show_pkg_var "short_desc" "$short_desc"
    show_pkg_var "subpackages" "$subpackages" 1
    set -f
    show_pkg_var "conf_files" "$conf_files" 1
    set +f
    show_pkg_var "replaces" "$replaces" 1
    show_pkg_var "provides" "$provides" 1
    show_pkg_var "conflicts" "$conflicts" 1
    local OIFS="$IFS"
    IFS=','
    for var in $1; do
        IFS=$OIFS
        if [ ${var} != ${var/'*'} ]
        then
            var="${var/'*'}"
            show_pkg_var "$var" "${!var//$'\n'/' '}"
        else
            show_pkg_var "$var" "${!var}" 1
        fi
    done
    IFS="$OIFS"

    return 0
}

show_pkg_var() {
    local _sep i=
    local _label="$1"
    local _value="$2"
    local _always_split="$3"
    if [ -n "$_value" ] && [ -n "$_label" ]; then
        # on short labels, use more padding so everything lines up
        if [ "${#_label}" -lt 7 ]; then
            _sep="		"
        else
            _sep="	"
        fi
        if [ -n "$_always_split" ] || [[ "$_value" =~ $'\n' ]]; then
            set -f
            for i in ${_value}; do
                [ -n "$i" ] && echo "${_label}:${_sep}${i}"
            done
            set +f
        else
            echo "${_label}:${_sep}${_value}"
        fi
    fi
}

show_pkg_deps() {
    [ -f "${XBPS_STATEDIR}/${pkgname}-rdeps" ] && cat "${XBPS_STATEDIR}/${pkgname}-rdeps"
}

show_pkg_files() {
    [ -d ${PKGDESTDIR} ] && find ${PKGDESTDIR} -print
}

show_avail() {
    check_pkg_arch "$XBPS_CROSS_BUILD" 2>/dev/null
}

show_eval_dep() {
    local f x _pkgname _srcpkg found
    local _dep="${1%-32bit}"
    local _host="$2"
    if [ -z "$CROSS_BUILD" ] || [ -z "$_host" ]; then
        # ignore dependency on itself
        [[ $_dep == $sourcepkg ]] && return
    fi
    if [ ! -f $XBPS_SRCPKGDIR/$_dep/template ]; then
        msg_error "$pkgver: dependency '$_dep' does not exist!\n"
    fi
    # ignore virtual dependencies
    [[ ${_dep%\?*} != ${_dep#*\?} ]] && _dep=${_dep#*\?}
    unset found
    # check for subpkgs
    for x in ${subpackages}; do
        [[ $_dep == $x ]] && found=1 && break
    done
    [[ $found ]] && return
    _srcpkg=$(readlink -f ${XBPS_SRCPKGDIR}/${_dep})
    _srcpkg=${_srcpkg##*/}
    echo $_srcpkg
}

show_pkg_build_depends() {
    local f result
    local _deps="$1"
    local _hostdeps="$2"

    result=$(mktemp) || exit 1

    # build time deps
    for f in ${_deps}; do
        show_eval_dep $f "" >> $result
    done
    for f in ${_hostdeps}; do
        show_eval_dep $f "hostdep" >> $result
    done
    sort -u $result
    rm -f $result
}

show_pkg_build_deps() {
    local build_depends="${makedepends} $(setup_pkg_depends '' 1 1)"
    skip_check_step || build_depends+=" ${checkdepends}"
    show_pkg_build_depends "${build_depends}" "${hostmakedepends}"
}

show_pkg_hostmakedepends() {
    show_pkg_build_depends "" "${hostmakedepends}"
}

show_pkg_makedepends() {
    show_pkg_build_depends "${makedepends}" ""
}

show_pkg_checkdepends() {
    show_pkg_build_depends "${checkdepends}" ""
}

show_pkg_build_options() {
    local f

    [ -z "$PKG_BUILD_OPTIONS" ] && return 0

    source $XBPS_COMMONDIR/options.description
    msg_normal "$pkgver: the following build options are set:\n"
    for f in ${PKG_BUILD_OPTIONS}; do
        local opt="${f#\~}"
        local descref="desc_option_${opt}"
        local desc="${!descref-Enable support for $opt}"
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
    [ -f "${XBPS_STATEDIR}/${pkgname}-shlib-provides" ] && cat "${XBPS_STATEDIR}/${pkgname}-shlib-provides"
}

show_pkg_shlib_requires() {
    [ -f "${XBPS_STATEDIR}/${pkgname}-shlib-requires" ] && cat "${XBPS_STATEDIR}/${pkgname}-shlib-requires"
}
