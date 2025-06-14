# Cross build profile for ARM EABI5 Hard Float and Musl libc.

XBPS_TARGET_MACHINE="armv6l-musl"
XBPS_TARGET_QEMU_MACHINE="arm"
XBPS_CROSS_TRIPLET="arm-linux-musleabihf"
XBPS_CROSS_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="arm-unknown-linux-musleabihf"
XBPS_CROSS_ZIG_TARGET="arm-linux-musleabihf"
XBPS_CROSS_ZIG_CPU="generic+v6"
