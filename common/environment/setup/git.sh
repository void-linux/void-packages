# If XBPS_USE_BUILD_MTIME is enabled in conf file don't continue.
# only run this, if SOURCE_DATE_EPOCH isn't set.
if [ -z "$XBPS_USE_BUILD_MTIME" -a -z "${SOURCE_DATE_EPOCH}" -a -n "$IN_CHROOT" ]; then
	if command -v chroot-git &>/dev/null; then
		GIT_CMD=$(command -v chroot-git)
	elif command -v git &>/dev/null; then
		GIT_CMD=$(command -v git)
	fi
	export SOURCE_DATE_EPOCH="$($GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} log --pretty='%ct' -n1 .)"
fi
