# This hooks removes empty dirs and warns about them.

hook() {
    if [ -d "${PKGDESTDIR}" ]; then
        find "${PKGDESTDIR}" -mindepth 1 -type d -empty -print -delete|sort -r|while read -r f; do
            _dir="${f##${PKGDESTDIR}}"
            msg_warn "$pkgver: removed empty dir: ${_dir}\n"
        done
    fi
}
