# This hook generates a file ${XBPS_STATEDIR}/gitrev with the last
# commit sha1 (in short mode) for source pkg if XBPS_USE_GIT_REVS is enabled.

hook() {
	local GITREVS_FILE=${XBPS_STATEDIR}/gitrev

	# If XBPS_USE_GIT_REVS is disabled in conf file don't continue.
	if [ -z $XBPS_USE_GIT_REVS ]; then
		return
	fi
	# If the file exists don't regenerate it again.
	if [ -s ${GITREVS_FILE} ]; then
		return
	fi

	if [ -z "$XBPS_GIT_REVS" ]; then
		msg_error "BUG: XBPS_GIT_REVS is not set\n"
	fi

	cd $XBPS_SRCPKGDIR
	echo "${sourcepkg}:${XBPS_GIT_REVS}"
	echo "${sourcepkg}:${XBPS_GIT_REVS}" > $GITREVS_FILE
}
