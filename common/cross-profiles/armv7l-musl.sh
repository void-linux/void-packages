# Cross build profile for ARMv7 EABI Hard Float and Musl libc.

XBPS_TARGET_MACHINE="armv7l-musl"
XBPS_CROSS_TRIPLET="armv7l-linux-musleabihf"
XBPS_CROSS_CFLAGS="-march=armv7-a -mfpu=vfpv3 -mfloat-abi=hard"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="armv7-unknown-linux-musleabihf"
