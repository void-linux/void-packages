# This hooks removes empty dirs and warns about them.

hook() {
    if [ -d "${PKGDESTDIR}" ]; then
        find "${PKGDESTDIR}" -type d -empty|sort -r|while read f; do
            _dir="${f##${PKGDESTDIR}}"
            [ -z "${_dir}" ] && continue
            rmdir --ignore-fail-on-non-empty -p "$f" &>/dev/null
            msg_warn "$pkgver: removed empty dir: ${_dir}\n"
        done
        # Create PKGDESTDIR in case it has been removed previously.
        mkdir -p ${PKGDESTDIR}
    fi
}
