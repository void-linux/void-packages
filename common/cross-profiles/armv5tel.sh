# Cross build profile for ARM GNU EABI5 Soft Float.
 
XBPS_TARGET_MACHINE="armv5tel"
XBPS_TARGET_QEMU_MACHINE="arm"
XBPS_CROSS_TRIPLET="arm-linux-gnueabi"
XBPS_CROSS_CFLAGS="-march=armv5te -msoft-float -mfloat-abi=soft"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
