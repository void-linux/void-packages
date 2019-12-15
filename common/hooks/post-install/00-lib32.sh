# This hook removes the /usr/lib32 symlink on 32-bit systems.

hook() {
	if [ "$XBPS_TARGET_WORDSIZE" = "32" ] && \
	   [ "${pkgname}" != "base-files" ]; then
		rm -f ${PKGDESTDIR}/usr/lib32
	fi
}
