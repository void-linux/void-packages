# If XBPS_USE_BUILD_MTIME is enabled in conf file don't continue.
# only run this, if SOURCE_DATE_EPOCH isn't set.
if [ -n "$XBPS_USE_BUILD_MTIME" ]; then
	unset SOURCE_DATE_EPOCH
	return 0
fi
if [ -z "${SOURCE_DATE_EPOCH}" -a -n "$IN_CHROOT" ]; then
	if command -v chroot-git &>/dev/null; then
		GIT_CMD=$(command -v chroot-git)
	elif command -v git &>/dev/null; then
		GIT_CMD=$(command -v git)
	fi
	# check if the template is under version control:
	if $GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} status -u normal --porcelain template | grep "^?? " &> /dev/null; then
		export SOURCE_DATE_EPOCH="$(stat -c %Y ${XBPS_SRCPKGDIR}/${basepkg}/template)"
	else
		export SOURCE_DATE_EPOCH="$($GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} log --pretty='%ct' -n1 .)"
	fi
fi
