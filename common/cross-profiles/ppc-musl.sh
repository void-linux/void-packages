# Cross build profile for PowerPC.

XBPS_TARGET_MACHINE="ppc-musl"
XBPS_CROSS_TRIPLET="powerpc-linux-musl"
XBPS_CROSS_CFLAGS="-mcpu=powerpc -mtune=G4 -mlong-double-64"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
