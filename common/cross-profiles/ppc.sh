# Cross build profile for PowerPC.

XBPS_TARGET_MACHINE="ppc"
XBPS_CROSS_TRIPLET="powerpc-linux-gnu"
XBPS_CROSS_CFLAGS="-mcpu=powerpc -mtune=G4"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
