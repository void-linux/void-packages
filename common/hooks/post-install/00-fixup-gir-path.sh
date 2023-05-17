# This hook removes the symlink necessary to fix the wrong install path of
# 'gir' files when cross building packages (see pre-install hook). It's a
# workaround and not a proper fix. Remove it once the root cause of the problem
# is fixed.

# Has to be a low number so it runs before remove-empty-dirs

hook() {
	[ -z "$CROSS_BUILD" ] && return
	rm -f "${PKGDESTDIR}/usr/${XBPS_CROSS_TRIPLET}/usr"
}
