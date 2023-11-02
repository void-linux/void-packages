# vim: set ts=4 sw=4 et:

show_pkg() {
    show_pkg_var no "pkgname" "$pkgname"
    show_pkg_var no "version" "$version"
    show_pkg_var no "revision" "$revision"
    show_pkg_var st "distfiles" "$distfiles"
    show_pkg_var st "checksum" "$checksum"
    show_pkg_var st "archs" "$archs"
    show_pkg_var no "maintainer" "${maintainer}"
    show_pkg_var no "Upstream URL" "$homepage"
    show_pkg_var st "License(s)" "${license//,/ }"
    show_pkg_var no "Changelog" "$changelog"
    show_pkg_var no "build_style" "$build_style"
    show_pkg_var st "build_helper" "$build_helper"
    show_pkg_var st "configure_args" "$configure_args"
    show_pkg_var no "short_desc" "$short_desc"
    show_pkg_var st "subpackages" "$subpackages"
    set -f
    show_pkg_var st "conf_files" "$conf_files"
    set +f
    show_pkg_var st "replaces" "$replaces"
    show_pkg_var st "provides" "$provides"
    show_pkg_var st "conflicts" "$conflicts"
    local OIFS="$IFS"
    IFS=','
    for var in $1; do
        IFS=$OIFS
        if [ ${var} != ${var/'*'} ]
        then
            var="${var/'*'}"
            show_pkg_var no "$var" "${!var//$'\n'/' '}"
        else
            show_pkg_var st "$var" "${!var}"
        fi
    done
    IFS="$OIFS"

    return 0
}

show_pkg_var() {
    local _sep i=
    local _split="$1"
    local _label="$2"
    shift 2
    if [ -n "$_label" ]; then
        # on short labels, use more padding so everything lines up
        if [ "${#_label}" -lt 7 ]; then
            _sep="		"
        else
            _sep="	"
        fi

        # treat as an array
        if [ "$_split" = "ar" ]; then
            for _value; do
                if [ -n "$_value" ]; then
                    if [[ "$_value" =~ $'\n' ]]; then
                        OIFS="$IFS"; IFS=$'\n'
                        for i in $_value; do
                            [ -n "$i" ] && echo "${_label}:${_sep}${i}"
                        done
                        IFS="$OIFS"
                    else
                        echo "${_label}:${_sep}${_value}"
                    fi
                fi
            done
        # treat as a string, always split at whitespace
        elif [ "$_split" = "st" ] || [[ "$@" =~ $'\n' ]]; then
            _value="$@"
            for i in $_value; do
                [ -n "$i" ] && echo "${_label}:${_sep}${i}"
            done
        else
            _value="$@"
            [ -n "$_value" ] && echo "${_label}:${_sep}${_value}"
        fi
    fi
}

show_pkg_arr() {
    local _sep i=
    local _label="$1"
    shift
    for _value; do
        # on short labels, use more padding so everything lines up
        if [ "${#_label}" -lt 7 ]; then
            _sep="		"
        else
            _sep="	"
        fi
    done
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
    show_pkg_build_depends "${makedepends} $(setup_pkg_depends '' 1 1)" "${hostmakedepends}"
}

show_pkg_hostmakedepends() {
    show_pkg_build_depends "" "${hostmakedepends}"
}

show_pkg_makedepends() {
    show_pkg_build_depends "${makedepends}" ""
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
    [ -f "${PKGDESTDIR}/shlib-provides" ] && cat ${PKGDESTDIR}/shlib-provides
}

show_pkg_shlib_requires() {
    [ -f "${PKGDESTDIR}/shlib-requires" ] && cat ${PKGDESTDIR}/shlib-requires
}
