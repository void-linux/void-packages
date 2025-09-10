# vim: set ts=4 sw=4 et ft=bash :
#
# This hook execute the following tasks:
# - warn if packages uses private Qt API but makedepends doesn't have
# qt6-*-private-devel
#
# This hook only really target qt6-base-private-devel, a lot of packages
# linked with Qt6::CorePrivate and Qt6::GuiPrivate, yet don't need its
# headers.

get_qt_private() {
    local _elf _fn _lf
    find ${PKGDESTDIR} -type f |
    while read -r _fn; do
        trap - ERR
        _lf=${_fn#${PKGDESTDIR}}
        if [ "${skiprdeps/${_lf}/}" != "${skiprdeps}" ]; then
            continue
        fi
        read -n4 _elf < "$_fn"
        if [ "$_elf" = $'\177ELF' ]; then
            $OBJDUMP -p "$_fn" |
            sed -n '
                /required from /{s/.*required from \(.*\):/\1/;h;}
                /Qt_[0-9]*_PRIVATE_API/{g;p;}
            '
        fi
    done |
    sort -u
}


hook() {
    local _list _shlib _version _md _v _ok

    if [ -n "$noverifyrdeps" ]; then
        return 0
    fi

    _list=$(get_qt_private)
    for _shlib in $_list; do
        msg_normal "${pkgver}: requires PRIVATE_API from $_shlib\n"
    done
    _version=$(printf '%s\n' $_list |
    sed -E '
        s/^libQt([0-9]*)3D.*/\1/
        s/^libQt([0-9]*).*/\1/
    ' | grep -v '^5$' | uniq
    )
    for _v in $_version; do
        _ok=
        for _md in ${makedepends}; do
            case "${_md}" in
                # Anything will works, because they're updated together
                qt${_v}-*-private-devel)
                    _ok=yes
                    break
                    ;;
            esac
        done
        if [ -z "$_ok" ]; then
            msg_warn "${pkgver}: using Qt${_v}_PRIVATE_API but doesn't use qt${_v}-*-private-devel\n"
        fi
    done
}
