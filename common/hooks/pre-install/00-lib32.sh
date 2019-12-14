# This hook creates the /usr/lib32 symlink for 32-bit systems.

hook() {
	if [ "$XBPS_TARGET_WORDSIZE" = "32" ] && \
	   [ "${pkgname}" != "base-files" ]; then
		vmkdir usr/lib
		ln -sf lib ${PKGDESTDIR}/usr/lib32
	fi
}
