# This snippet setups pkg-config vars.

if [ -z "$CHROOT_READY" ]; then
	export PKG_CONFIG_PATH="${XBPS_MASTERDIR}/usr/lib/pkgconfig:${XBPS_MASTERDIR}/usr/share/pkgconfig"
fi
if [ -n "$CROSS_BUILD" ]; then
	export PKG_CONFIG="${XBPS_CROSS_TRIPLET}-pkg-config"
fi
