# Cross build profile for ppc64 little-endian musl.

XBPS_TARGET_MACHINE="ppc64le-musl"
XBPS_TARGET_QEMU_MACHINE="ppc64le"
XBPS_CROSS_TRIPLET="powerpc64le-linux-musl"
XBPS_CROSS_CFLAGS="-mtune=power9"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="powerpc64le-unknown-linux-musl"
XBPS_CROSS_ZIG_TARGET="powerpc64le-linux-musl"
XBPS_CROSS_ZIG_CPU="baseline"
