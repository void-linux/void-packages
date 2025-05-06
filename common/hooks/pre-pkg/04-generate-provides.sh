# vim: set ts=4 sw=4 ft=bash et:
#
# This hook executes the following tasks:
#	- Generates provides file with provides entries for xbps-create(1)

get_explicit_provides() {
    # include explicit values from the template
    if [ -n "$provides" ]; then
        printf '%s\n' $provides
    fi
}

generate_python_provides() {
    local py3_bin="${XBPS_MASTERDIR}/usr/bin/python3"

    # get the canonical python package names for each python module
    if [ -z "$nopyprovides" ] && [ -d "${PKGDESTDIR}/${py3_sitelib}" ] && [ -x "${py3_bin}" ]; then
        PYTHONPATH="${XBPS_MASTERDIR}/${py3_sitelib}-bootstrap" "${py3_bin}" \
            "${XBPS_COMMONDIR}"/scripts/parse-py-metadata.py \
            -S "${PKGDESTDIR}/${py3_sitelib}" -v "${pkgver}" provides
    fi
}

generate_pkgconfig_provides() {
    find "${PKGDESTDIR}/usr/lib/pkgconfig" "${PKGDESTDIR}/usr/share/pkgconfig" -name '*.pc' -type f \
        -exec pkg-config --print-provides {} \; 2>/dev/null | sed "s/^/pc:/; s/ =.*/-${version}_${revision}/" | sort -u
}

generate_cmd_provides() {
    find "${PKGDESTDIR}/usr/bin" -maxdepth 1 -type f -printf "cmd:%f-${version}_${revision}\n" 2>/dev/null | sort -u
}

generate_alt_cmd_provides() {
    local _alt _group _symlink _target _path
    for _alt in $alternatives; do
        IFS=':' read -r _group _symlink _target <<< "$_alt"
        case "$_symlink" in
            /usr/bin/*)
                echo "${_symlink##*/}"
                ;;
            /*)
                # skip all other absolute paths
                ;;
            */*)
                # relative path, resolve
                _path="$(realpath -m "$_target/./$_symlink")"
                if [ "${_path%/*}" = /usr/bin ]; then
                    echo "${_path##*/}"
                fi
                ;;
            *)
                if [ "${_target%/*}" = /usr/bin ]; then
                    echo "${_symlink}"
                fi
                ;;
        esac
    done | sed "s/^/cmd:/; s/$/-0_1/"
}

hook() {
    local -a _provides

    mapfile -t _provides < <(
        get_explicit_provides
        generate_python_provides
        generate_pkgconfig_provides
        generate_cmd_provides
        generate_alt_cmd_provides
    )

    if [ "${#_provides[@]}" -gt 0 ]; then
        echo "   ${_provides[*]}"
        echo "${_provides[*]}" > "${XBPS_STATEDIR}/${pkgname}-provides"
    fi
}
