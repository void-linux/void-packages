# This snippet setups pkg-config vars.

if [ -z "$CHROOT_READY" ]; then
	export PKG_CONFIG_PATH="${XBPS_MASTERDIR}/usr/lib/pkgconfig:${XBPS_MASTERDIR}/usr/share/pkgconfig"
fi
