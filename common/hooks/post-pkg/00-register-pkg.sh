# This hook registers a XBPS binary package into the specified local repository.

registerpkg() {
	local repo="$1" pkg="$2" arch="$3"

	if [ ! -f ${repo}/${pkg} ]; then
		msg_error "Unexistent binary package ${repo}/${pkg}!\n"
	fi

	msg_normal "Registering ${pkg} into ${repo} ...\n"
	if [ -n "${arch}" ]; then
		XBPS_TARGET_ARCH=${arch} $XBPS_RINDEX_CMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
	else
		if [ -n "$XBPS_CROSS_BUILD" ]; then
			$XBPS_RINDEX_XCMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
		else
			$XBPS_RINDEX_CMD ${XBPS_BUILD_FORCEMODE:+-f} -a ${repo}/${pkg}
		fi
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
	if [ -z "$noarch" -a -z "$XBPS_CROSS_BUILD" -a -n "$XBPS_ARCH" -a "$XBPS_ARCH" != "$XBPS_TARGET_MACHINE" ]; then
		arch=${XBPS_ARCH}
	fi
	if [ -n "$repository" ]; then
		pkgdir=$XBPS_REPOSITORY/$repository
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
	pkgdir=$XBPS_REPOSITORY/debug
	PKGDESTDIR="${XBPS_DESTDIR}/${XBPS_CROSS_TRIPLET}/${pkgname}-dbg-${version}"
	if [ -d ${PKGDESTDIR} -a -f ${pkgdir}/${binpkg_dbg} ]; then
		registerpkg ${pkgdir} ${binpkg_dbg}
	fi

	# Register 32bit binpkg if it exists.
	if [ "$XBPS_TARGET_MACHINE" != "i686" ]; then
		return
	fi
	if [ -n "$repository" ]; then
		pkgdir=$XBPS_REPOSITORY/multilib/$repository
	else
		pkgdir=$XBPS_REPOSITORY/multilib
	fi
	PKGDESTDIR="${XBPS_DESTDIR}/${pkgname}-32bit-${version}"
	if [ -d ${PKGDESTDIR} -a -f ${pkgdir}/${binpkg32} ]; then
		registerpkg ${pkgdir} ${binpkg32} x86_64
	fi
}
