# This hook fixes the wrong install path of 'gir' files
# when cross building packages. It's a workaround and
# not a proper fix. Remove it once the root cause of the
# problem is fixed.

hook() {
	[ -z "$CROSS_BUILD" ] && return
	if [ -d "${DESTDIR}/usr/${XBPS_CROSS_TRIPLET}/usr" ]; then
		cp -a "${DESTDIR}"/usr/{${XBPS_CROSS_TRIPLET}/usr/*,}
		rm -rf "${DESTDIR}"/usr/${XBPS_CROSS_TRIPLET}/usr
	fi
}
