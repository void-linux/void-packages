# Cross build profile for i686 and Musl libc.

XBPS_TARGET_ARCH="i686-musl"
XBPS_CROSS_TRIPLET="i686-linux-musl"
XBPS_CROSS_CFLAGS="-march=i686"
# XXX disable SSP and _FORTIFY_SOURCE
XBPS_CFLAGS="-O2 -pipe -fno-stack-protector"
XBPS_CPPFLAGS=
XBPS_CXXFLAGS="$XBPS_CFLAGS"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
