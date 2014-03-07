# This hook registers a XBPS binary package into the specified local repository.

registerpkg() {
	local repo="$1" pkg="$2" arch="$3"

	if [ ! -f ${repo}/${pkg} ]; then
		msg_error "Unexistent binary package ${repo}/${pkg}!\n"
	fi

	if [ -n "${arch}" ]; then
		export XBPS_TARGET_ARCH=${arch}
	fi
	msg_normal "Registering ${pkg} into ${repo} ...\n"

	if [ -n "$XBPS_CROSS_BUILD" ]; then
		$XBPS_RINDEX_XCMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
	else
		$XBPS_RINDEX_CMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
	fi
	unset XBPS_TARGET_ARCH
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
	binpkg32=${pkgname}-32bit-${version}_${revision}.x86_64.xbps
	binpkg_dbg=${pkgname}-dbg-${version}_${revision}.${arch}.xbps

	# Register binpkg.
	if [ -f ${pkgdir}/${binpkg} ]; then
		registerpkg ${pkgdir} ${binpkg}
	fi

	# Register -dbg binpkg if it exists.
	if [ -f ${pkgdir}/${binpkg_dbg} ]; then
		registerpkg ${pkgdir} ${binpkg_dbg}
	fi

	# Register 32bit binpkg if it exists.
	if [ "$XBPS_TARGET_MACHINE" != "i686" ]; then
		return
	fi
	if [ -f ${pkgdir}/${binpkg32} ]; then
		registerpkg ${pkgdir} ${binpkg32} x86_64
	fi
}
