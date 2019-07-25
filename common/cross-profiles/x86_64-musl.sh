# Cross build profile for x86_64 and Musl libc.
XBPS_TARGET_WORDSIZE=64
XBPS_TARGET_MACHINE="x86_64-musl"
XBPS_TARGET_QEMU_MACHINE="x86_64"
XBPS_CROSS_TRIPLET="x86_64-linux-musl"
XBPS_CROSS_CFLAGS="-mtune=generic"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="x86_64-unknown-linux-musl"
