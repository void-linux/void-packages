# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#	- Verifies python module dependencies from dist-info's METADATA and egg-info's PKG-INFO

hook() {
    local py3_bin="${XBPS_MASTERDIR}/usr/bin/python3"

    if [ -z "$noverifypydeps" ] && [ -d "${PKGDESTDIR}/${py3_sitelib}" ] && [ -x "${py3_bin}" ]; then
            PYTHONPATH="${XBPS_MASTERDIR}/${py3_sitelib}-bootstrap" "${py3_bin}" \
                "${XBPS_COMMONDIR}"/scripts/parse-py-metadata.py \
                ${NOCOLORS:+-C} ${XBPS_STRICT:+-s} -S "${PKGDESTDIR}/${py3_sitelib}" -v "${pkgver}" \
                depends -e "${python_extras}" \
                -V <( $XBPS_QUERY_XCMD -R -p provides -s "py3:" ) -D "${XBPS_STATEDIR}/${pkgname}-rdeps" \
                -G <( $XBPS_QUERY_XCMD -o '/usr/lib/girepository-*/*.typelib' ) \
                || msg_error "$pkgver: failed to verify python module dependencies\n"
    fi
}
