# Cross build profile for ARM GNU EABI5 Hard Float.

XBPS_TARGET_ARCH="armv6l"
XBPS_CROSS_TRIPLET="arm-linux-gnueabihf"
XBPS_CROSS_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
