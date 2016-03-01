# If XBPS_USE_BUILD_MTIME is enabled in conf file don't continue.
# only run this, if XBPS_COMMIT_TIMESTAMP isn't set
if [ -z "$XBPS_USE_BUILD_MTIME" ] && [ -z "${XBPS_COMMIT_TIMESTAMP}" ]; then
	if command -v chroot-git &>/dev/null; then
		GIT_CMD=$(command -v chroot-git)
	elif command -v git &>/dev/null; then
		GIT_CMD=$(command -v git)
	fi
	export XBPS_COMMIT_TIMESTAMP="$($GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} log --pretty='%ci' --date=iso -n1 .)"
fi
