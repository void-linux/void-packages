# This hook creates the wordsize specific libdir symlink.

hook() {
	if [ "${pkgname}" != "base-files" ]; then
		vmkdir usr/lib
		ln -sf lib ${PKGDESTDIR}/usr/lib${XBPS_TARGET_WORDSIZE}
	fi
}
