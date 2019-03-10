# Cross build profile for ARM GNU EABI5 Hard Float.

XBPS_TARGET_MACHINE="armv6l"
XBPS_CROSS_TRIPLET="arm-linux-gnueabihf"
XBPS_CROSS_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="arm-unknown-linux-gnueabihf"
