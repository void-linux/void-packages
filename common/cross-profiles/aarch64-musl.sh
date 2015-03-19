# Cross build profile for ARMv8.

XBPS_TARGET_ARCH="aarch64-musl"
XBPS_CROSS_TRIPLET="aarch64-linux-musl"
XBPS_CFLAGS="-O2 -pipe" # XXX not yet supported: -fstack-protector-strong
XBPS_CXXFLAGS="$XBPS_CFLAGS"
XBPS_CROSS_CFLAGS="-march=armv8-a"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
