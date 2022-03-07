# Cross build profile for MIPS32 BE soft float.

XBPS_TARGET_MACHINE="mips-musl"
XBPS_TARGET_QEMU_MACHINE="mips"
XBPS_CROSS_TRIPLET="mips-linux-musl"
XBPS_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -msoft-float"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="mips-unknown-linux-musl"
XBPS_CROSS_ZIG_TARGET="mips-linux-musl"
XBPS_CROSS_ZIG_CPU="generic+soft_float"
