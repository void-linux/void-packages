# This file sets some envvars to allow building bootstrap packages
# when the chroot is not yet ready.

[ -z "$CHROOT_READY" ] && return 0

export PKG_CONFIG_PATH="${XBPS_MASTERDIR}/usr/lib/pkgconfig:${XBPS_MASTERDIR}/usr/share/pkgconfig"
