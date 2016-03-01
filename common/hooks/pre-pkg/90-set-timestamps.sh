# This hook executes the following tasks:
#	- sets the timestamps in a package to the commit date

hook() {
	# If XBPS_COMMIT_TIMESTAMP is set, set mtimes to that timestamp.
	if [ -n "$XBPS_COMMIT_TIMESTAMP" ]; then
		msg_normal "$pkgver: setting mtimes to %s\n" "$(date --date "$XBPS_COMMIT_TIMESTAMP")"
		find $PKGDESTDIR -print0 | xargs -0 touch -h --date "$XBPS_COMMIT_TIMESTAMP"
	fi
}
