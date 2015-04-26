# This hooks removes empty dirs and warns about them.

hook() {
	find ${PKGDESTDIR} -type d -empty -print0|sort -z -r|while IFS="" read f; do
		_dir="${f##${PKGDESTDIR}}"
		[ -z "${_dir}" ] && continue
		rmdir --ignore-fail-on-non-empty -p "$f" &>/dev/null
		msg_warn "$pkgver: removed empty dir: ${_dir}\n"
	done
	# Create PKGDESTDIR in case it has been removed previously.
	mkdir -p ${PKGDESTDIR}
}
