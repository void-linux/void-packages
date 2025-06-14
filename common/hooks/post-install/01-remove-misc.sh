# hook to remove misc files.
hook() {
	case "$XBPS_TARGET_MACHINE" in
		*-musl) ;;
		*) return 0;;
	esac
	# Remove charset.alias on musl
	if [ -f $PKGDESTDIR/usr/lib/charset.alias ]; then
		rm -f $PKGDESTDIR/usr/lib/charset.alias
	fi
}
