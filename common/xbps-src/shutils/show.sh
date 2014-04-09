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
    for i in ${conf_files}; do
        [ -n "$i" ] && echo "conf_files:	$i"
    done
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
}

show_pkg_deps() {
    [ -f "${PKGDESTDIR}/rdeps" ] && cat ${PKGDESTDIR}/rdeps
}

show_pkg_files() {
    [ -d ${PKGDESTDIR} ] && find ${PKGDESTDIR} -print
}

show_pkg_build_deps() {
    local f=

    # build time deps
    for f in ${hostmakedepends} ${makedepends}; do
        echo "$f"
    done
}

show_pkg_options() {
    local f= j= state= desc= enabled=

    for f in ${build_options}; do
        for j in ${build_options_default}; do
            if [ "$f" = "$j" ]; then
                enabled=1
                break
            fi
        done
        state="OFF"
        if [ -n "$enabled" ]; then
            state="ON"
            unset enabled
        fi
        eval desc="\$desc_option_$f"
        printf "$f: $desc [$state]\n"
    done
}

show_pkg_shlib_provides() {
    [ -f "${PKGDESTDIR}/shlib-provides" ] && cat ${PKGDESTDIR}/shlib-provides
}

show_pkg_shlib_requires() {
    [ -f "${PKGDESTDIR}/shlib-requires" ] && cat ${PKGDESTDIR}/shlib-requires
}
