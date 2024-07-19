# This hook removes libtool archives (.la) unless $keep_libtool_archives is set.

hook() {
	if [ -z "$keep_libtool_archives" -a -d "${PKGDESTDIR}" ]; then
		find ${PKGDESTDIR} -name \*.la -delete
	fi
}
