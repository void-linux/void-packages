# This hook warns if :
# - Any text file /usr/{bin,lib,libexec,share} contains $XBPS_CROSS_BASE
# - Any text file /usr/{bin,lib,libexec,share} contains $XBPS_WRAPPERDIR

hook() {
	if [ -z "$CROSS_BUILD" ]; then
		return 0
	fi
	for d in bin lib libexec share; do
		for f in $PKGDESTDIR/usr/$d/* $PKGDESTDIR/usr/$d/**/*; do
			case "$(file -bi "$f")" in
			text/*) if grep -q -e "$XBPS_CROSS_BASE" \
					   -e "$XBPS_WRAPPERDIR" "$f"; then
					msg_warn "${f#$PKGDESTDIR} has cross cruft\n"
				fi
				;;
			esac
		done
	done
	return 0;
}
