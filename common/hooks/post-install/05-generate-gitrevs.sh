# This hook generates a file in ${wrksrc}/.xbps_git_revs with the last
# commit sha1 (in short mode) for all files of a source pkg.

hook() {
	local GITREVS_FILE=${wrksrc}/.xbps_${sourcepkg}_git_revs
	local rev

	# If XBPS_USE_GIT_REVS is disabled in conf file don't continue.
	if [ -z $XBPS_USE_GIT_REVS ]; then
		return
	fi
	# If the file exists don't regenerate it again.
	if [ -s ${GITREVS_FILE} ]; then
		return
	fi

	cd $XBPS_SRCPKGDIR
	rev="$(chroot-git rev-parse --short HEAD)"
	echo "${sourcepkg}:${rev}"
	echo "${sourcepkg}:${rev}" > $GITREVS_FILE
}
