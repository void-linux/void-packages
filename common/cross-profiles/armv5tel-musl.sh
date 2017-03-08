# Cross build profile for ARM GNU EABI5 Soft Float and Musl libc.

XBPS_TARGET_MACHINE="armv5tel-musl"
XBPS_CROSS_TRIPLET="arm-linux-musleabi"
XBPS_CROSS_CFLAGS="-march=armv5te -msoft-float -mfloat-abi=soft"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
