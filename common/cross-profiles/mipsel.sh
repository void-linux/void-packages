# Cross build profile for MIPS LE soft float.

XBPS_TARGET_ARCH="mipsel"
XBPS_CROSS_TRIPLET="mipsel-softfloat-linux-gnu"
XBPS_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -msoft-float"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
