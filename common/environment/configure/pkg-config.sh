# This snippet setups pkg-config vars.

set -a

if [ -z "$CHROOT_READY" ]; then
	PKG_CONFIG_PATH="${XBPS_MASTERDIR}/usr/lib/pkgconfig:${XBPS_MASTERDIR}/usr/share/pkgconfig"
fi

set +a
