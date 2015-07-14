# Cross build profile for MIPS32 LE soft float.

XBPS_TARGET_ARCH="mipsel-musl"
XBPS_CROSS_TRIPLET="mipsel-linux-musl"
XBPS_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -msoft-float"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
