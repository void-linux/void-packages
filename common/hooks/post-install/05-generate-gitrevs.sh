# This hook generates a file ${XBPS_STATEDIR}/gitrev with the last
# commit sha1 (in short mode) for source pkg if XBPS_USE_GIT_REVS is enabled.

hook() {
	local GITREVS_FILE=${XBPS_STATEDIR}/gitrev
	local GIT_CMD rev

	# If XBPS_USE_GIT_REVS is disabled in conf file don't continue.
	if [ -z $XBPS_USE_GIT_REVS ]; then
		return
	fi
	# If the file exists don't regenerate it again.
	if [ -s ${GITREVS_FILE} ]; then
		return
	fi

	if command -v chroot-git &>/dev/null; then
		GIT_CMD=$(command -v chroot-git)
	elif command -v git &>/dev/null; then
		GIT_CMD=$(command -v git)
	else
		msg_error "$pkgver: cannot find chroot-git or git utility, exiting...\n"
	fi

	cd $XBPS_SRCPKGDIR
	rev="$($GIT_CMD rev-parse --short HEAD)"
	echo "${sourcepkg}:${rev}"
	echo "${sourcepkg}:${rev}" > $GITREVS_FILE
}
