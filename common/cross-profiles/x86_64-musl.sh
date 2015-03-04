# Cross build profile for x86_64 and Musl libc.

XBPS_TARGET_ARCH="x86_64-musl"
XBPS_CROSS_TRIPLET="x86_64-linux-musl"
XBPS_CROSS_CFLAGS="-mtune=generic"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
