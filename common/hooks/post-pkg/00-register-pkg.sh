# This hook registers a XBPS binary package into the specified local repository.

registerpkg() {
	local repo="$1" pkg="$2"

	if [ ! -f ${repo}/${pkg} ]; then
		msg_error "Unexistent binary package ${repo}/${pkg}!\n"
	fi

	msg_normal "Registering ${pkg} into ${repo} ...\n"

	if [ -n "$XBPS_CROSS_BUILD" ]; then
		$XBPS_RINDEX_XCMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
	else
		$XBPS_RINDEX_CMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
	fi
}

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
	if [ -n "$nonfree" ]; then
		pkgdir=$XBPS_REPOSITORY/nonfree
	else
		pkgdir=$XBPS_REPOSITORY
	fi
	binpkg=${pkgver}.${arch}.xbps
	binpkg_dbg=${pkgver}-dbg.${arch}.xbps

	# Register binpkg.
	registerpkg $pkgdir $binpkg

	# Register -dbg binpkg if it exists.
	if [ -f ${pkgdir}/${binpkg_dbg} ]; then
		registerpkg ${pkgdir} ${binpkg_dbg}
	fi
}
