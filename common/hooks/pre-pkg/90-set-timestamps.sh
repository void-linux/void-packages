# This hook executes the following tasks:
#	- sets the timestamps in a package to the commit date

hook() {
	local GIT_CMD date basepkg

	# If XBPS_USE_GIT_COMMIT_DATE is disabled in conf file don't continue.
	if [ -z $XBPS_USE_GIT_COMMIT_DATE ]; then
		return
	fi

	if command -v chroot-git &>/dev/null; then
		GIT_CMD=$(command -v chroot-git)
	elif command -v git &>/dev/null; then
		GIT_CMD=$(command -v git)
	else
		msg_error "$pkgver: cannot find chroot-git or git utility, exiting...\n"
	fi
	basepkg=$pkgname
	if [ -L "${XBPS_SRCPKGDIR}/$basepkg" ]; then
		basepkg=$(readlink "${XBPS_SRCPKGDIR}/$basepkg")
	fi
	date=$($GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} log --pretty='%ci' --date=iso -n1 .)
	msg_normal "$pkgver: setting mtimes to %s\n" "$(date --date "$date")"
	find $PKGDESTDIR -print0 | xargs -0 touch --date "$date"
}
