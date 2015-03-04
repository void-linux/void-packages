# Cross build profile for ARM EABI5 Hard Float and Musl libc.

XBPS_TARGET_ARCH="armv6l-musl"
XBPS_CROSS_TRIPLET="arm-linux-musleabi"
XBPS_CROSS_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
