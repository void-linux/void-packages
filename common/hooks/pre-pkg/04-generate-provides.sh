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

hook() {
    local -a _provides

    mapfile -t _provides < <(
        get_explicit_provides
        generate_python_provides
    )

    if [ "${#_provides[@]}" -gt 0 ]; then
        echo "   ${_provides[*]}"
        echo "${_provides[*]}" > "${XBPS_STATEDIR}/${pkgname}-provides"
    fi
}
