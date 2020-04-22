# If XBPS_USE_BUILD_MTIME is enabled in conf file don't continue.
# only run this, if SOURCE_DATE_EPOCH isn't set.

if [ -z "$XBPS_GIT_CMD" ]; then
	msg_error "BUG: environment/setup: XBPS_GIT_CMD is not set\n"
fi

if [ -n "$XBPS_USE_BUILD_MTIME" ]; then
	unset SOURCE_DATE_EPOCH
elif [ -z "${SOURCE_DATE_EPOCH}" -a -n "$IN_CHROOT" ]; then
	# check if the template is under version control:
	if $XBPS_GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} status -u normal --porcelain template | grep "^?? " &> /dev/null; then
		export SOURCE_DATE_EPOCH="$(stat -c %Y ${XBPS_SRCPKGDIR}/${basepkg}/template)"
	else
		export SOURCE_DATE_EPOCH="$($XBPS_GIT_CMD -C ${XBPS_DISTDIR} log --pretty='%ct' -n1 HEAD)"
	fi
fi
