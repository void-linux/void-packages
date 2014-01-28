# This file sets some envvars to allow cross compiling packages.

[ -z "$CROSS_BUILD" ] && return 0

export PKG_CONFIG_SYSROOT_DIR="$XBPS_CROSS_BASE"
export PKG_CONFIG_PATH="$XBPS_CROSS_BASE/lib/pkgconfig:$XBPS_CROSS_BASE/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$XBPS_CROSS_BASE/lib/pkgconfig"
export configure_args+=" --host=$XBPS_CROSS_TRIPLET --with-sysroot=$XBPS_CROSS_BASE --with-libtool-sysroot=$XBPS_CROSS_BASE "
