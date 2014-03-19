# This snippet setups pkg-config vars.

set -a

if [ -z "$CHROOT_READY" ]; then
	PKG_CONFIG_PATH="${XBPS_MASTERDIR}/usr/lib/pkgconfig:${XBPS_MASTERDIR}/usr/share/pkgconfig"
fi

if [ "$CROSS_BUILD" ]; then
	PKG_CONFIG_SYSROOT_DIR="$XBPS_CROSS_BASE"
	PKG_CONFIG_PATH="$XBPS_CROSS_BASE/lib/pkgconfig:$XBPS_CROSS_BASE/usr/share/pkgconfig"
	PKG_CONFIG_LIBDIR="$XBPS_CROSS_BASE/lib/pkgconfig"
fi

set +a
