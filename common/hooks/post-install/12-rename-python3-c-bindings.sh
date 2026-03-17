# This hook executes the following tasks:
#	- renames cpython binding files to not include the arch-specific extension suffix

hook() {
	if [ ! -d ${PKGDESTDIR}/${py3_sitelib} ]; then
		return 0
	fi

	find "${PKGDESTDIR}/${py3_sitelib}" -type f -executable -iname '*.cpython*.so' \
		| while read -r file; do
		filename="${file##*/}"
		modulename="${filename%%.*}"
		msg_warn "${pkgver}: renamed '${filename}' to '${modulename}.so'.\n"
		mv ${file} ${file%/*}/${modulename}.so
	done
}
