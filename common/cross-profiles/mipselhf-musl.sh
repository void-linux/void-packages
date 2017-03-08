# Cross build profile for MIPS32 LE hardfloat.

XBPS_TARGET_MACHINE="mipselhf-musl"
XBPS_CROSS_TRIPLET="mipsel-linux-muslhf"
XBPS_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -mhard-float"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
