# Cross build profile for riscv64 and Musl libc.

XBPS_TARGET_MACHINE="riscv64-musl"
XBPS_TARGET_QEMU_MACHINE="riscv64"
XBPS_CROSS_TRIPLET="riscv64-linux-musl"
XBPS_CROSS_CFLAGS="-march=rv64imafdc"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="riscv64gc-unknown-linux-musl"
XBPS_CROSS_ZIG_TARGET="riscv64-linux-musl"
XBPS_CROSS_ZIG_CPU="baseline"
