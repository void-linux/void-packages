# Cross build profile for ARMv7 EABI Hard Float and Musl libc.

XBPS_TARGET_ARCH="armv7l-musl"
XBPS_CROSS_TRIPLET="arm-linux-musleabi"
XBPS_CFLAGS="-O2 -pipe -fstack-protector-strong"
XBPS_CXXFLAGS="$XBPS_CFLAGS"
XBPS_CROSS_CFLAGS="-march=armv7-a -mfpu=vfpv3 -mfloat-abi=hard"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
