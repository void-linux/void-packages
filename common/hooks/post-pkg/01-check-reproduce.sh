# This hook compares the checksum of the package with the saved value

hook() {
	local arch= binpkg= checksum_ptr= checksum_have= checksum_want=

	if [ -z "$XBPS_CHECK_REPRODUCIBLE" ]; then
		return 0;
	fi

	if [ -z "$XBPS_USE_BUILD_MTIME" ]; then
		msg_warn "reproducability check will only report correct results when\n"
		msg_warn "XBPS_USE_BUILD_MTIME is enabled.\n"
	fi

	if [ -z "$XBPS_CROSS_BUILD" -a -n "$XBPS_ARCH" -a "$XBPS_ARCH" != "$XBPS_TARGET_MACHINE" ]; then
		arch=${XBPS_ARCH}
	elif [ -n "$XBPS_TARGET_MACHINE" ]; then
		arch=$XBPS_TARGET_MACHINE
	else
		arch=$XBPS_MACHINE
	fi
	binpkg=${pkgver}.${arch}.xbps

	checksum_ptr="pkg_checksum_${arch//-/_}"
	checksum_want=${!checksum_ptr}

	checksum_have=$(sha256sum "$binpkg" | awk '{ print $1 }')

	if [ -z "${checksum_want}" ]; then
		msg_normal "$pkgver: template does not define a pkg_checksum\n"
		msg_normal "$pkgver: if the build is reproducable define the package checksum in the template:\n"
		msg_normal "$pkgver: $checksum_ptr="$checksum_want"\n"
		return 0
	fi

	if [ "${checksum_have}" != "${checksum_want}" ]; then
		msg_warn "${pkgver}: Checksum mismatch. reproducable build seems to be broken.\n"
		msg_warn "${pkgver}: Gather relevant system info:\n"
		msg_normal "CPU: $(grep "^model name" /proc/cpuinfo | head -n 1 | sed 's/.*: //')"
	else
		msg_normal "${pkgver}: Checksums patch; build seems to be reproducable.\n"
	fi
}
