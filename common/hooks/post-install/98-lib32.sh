# This hook removes the /usr/lib32 symlink on x86.

hook() {
	if [ "$XBPS_TARGET_MACHINE" = "i686" ]; then
		rm -f ${PKGDESTDIR}/usr/lib32
	fi
}
