# If XBPS_USE_BUILD_MTIME is enabled in conf file don't continue.
# only run this, if SOURCE_DATE_EPOCH isn't set.

if [ -z "$XBPS_GIT_CMD" ]; then
	if [ -z "$XBPS_USE_BUILD_MTIME" ] || [ -n "$XBPS_USE_GIT_REVS" ]; then
		msg_error "BUG: environment/setup: XBPS_GIT_CMD is not set\n"
	fi
fi

if [ -n "$XBPS_USE_BUILD_MTIME" ]; then
	unset SOURCE_DATE_EPOCH
elif [ -z "${SOURCE_DATE_EPOCH}" ]; then
	if [ -n "$IN_CHROOT" ]; then
		msg_error "xbps-src's BUG: SOURCE_DATE_EPOCH is undefined\n"
	fi
	# check if the template is under version control:
	if [ -n "$basepkg" -a -z "$($XBPS_GIT_CMD -C ${XBPS_SRCPKGDIR}/${basepkg} ls-files template)" ]; then
		export SOURCE_DATE_EPOCH="$(stat_mtime ${XBPS_SRCPKGDIR}/${basepkg}/template)"
	else
		export SOURCE_DATE_EPOCH=$($XBPS_GIT_CMD -C ${XBPS_DISTDIR} cat-file commit HEAD |
			sed -n '/^committer /{s/.*> \([0-9][0-9]*\) [-+][0-9].*/\1/p;q;}')
	fi
fi

# if XBPS_USE_GIT_REVS is enabled in conf file,
# compute XBPS_GIT_REVS to use in pkg hooks
if [ -z "$XBPS_USE_GIT_REVS" ]; then
	unset XBPS_GIT_REVS
elif [ -z "$XBPS_GIT_REVS" ]; then
	if [ -n "$IN_CHROOT" ]; then
		msg_error "xbps-src's BUG: XBPS_GIT_REVS is undefined\n"
	else
		export XBPS_GIT_REVS="$($XBPS_GIT_CMD -C "${XBPS_DISTDIR}" rev-parse --verify --short HEAD)"
	fi
fi
