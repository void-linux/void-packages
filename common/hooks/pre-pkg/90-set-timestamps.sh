# This hook executes the following tasks:
#	- sets the timestamps in a package to the commit date

hook() {
	# If SOURCE_DATE_EPOCH is set, set mtimes to that timestamp.
	if [ -n "$SOURCE_DATE_EPOCH" ]; then
		msg_normal "$pkgver: setting mtimes to %s\n" "$(date --date "@$SOURCE_DATE_EPOCH")"
		find $PKGDESTDIR -print0 | xargs -0 touch -h --date "@$SOURCE_DATE_EPOCH"
	fi
}
