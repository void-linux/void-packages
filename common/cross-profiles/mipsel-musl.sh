# Cross build profile for MIPS32 LE soft float.

XBPS_TARGET_MACHINE="mipsel-musl"
XBPS_TARGET_QEMU_MACHINE="mipsel"
XBPS_CROSS_TRIPLET="mipsel-linux-musl"
XBPS_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -msoft-float"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="mipsel-unknown-linux-musl"
XBPS_CROSS_ZIG_TARGET="mipsel-linux-musl"
XBPS_CROSS_ZIG_CPU="generic+soft_float"
