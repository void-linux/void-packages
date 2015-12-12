# Cross build profile for i686 and Musl libc.

XBPS_TARGET_ARCH="i686-musl"
XBPS_CROSS_TRIPLET="i686-linux-musl"
XBPS_CROSS_CFLAGS="-march=i686"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
