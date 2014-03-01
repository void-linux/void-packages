# This hook registers a XBPS binary package into the specified local repository.

hook() {
	local arch= binpkg= pkgdir=

	if [ -n "$noarch" ]; then
		arch=noarch
	elif [ -n "$XBPS_TARGET_MACHINE" ]; then
		arch=$XBPS_TARGET_MACHINE
	else
		arch=$XBPS_MACHINE
	fi
	if [ -z "$noarch" -a -n "$XBPS_ARCH" -a "$XBPS_ARCH" != "$XBPS_TARGET_MACHINE" ]; then
		arch=${XBPS_ARCH}
	fi
	binpkg=$pkgver.$arch.xbps
	if [ -n "$nonfree" ]; then
		pkgdir=$XBPS_REPOSITORY/nonfree
	else
		pkgdir=$XBPS_REPOSITORY
	fi

	if [ ! -f ${pkgdir}/${binpkg} ]; then
		msg_error "Unexistent binary package ${pkgdir}/${binpkg}!\n"
	fi

	msg_normal "Registering ${binpkg} into ${pkgdir} ...\n"

	if [ -n "$XBPS_CROSS_BUILD" ]; then
		$XBPS_RINDEX_XCMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${pkgdir}/${binpkg}
	else
		$XBPS_RINDEX_CMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${pkgdir}/${binpkg}
	fi
}
