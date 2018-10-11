# Cross build profile for ARMv8.

XBPS_TARGET_MACHINE="aarch64"
XBPS_CROSS_TRIPLET="aarch64-linux-gnu"
XBPS_CFLAGS="-O2 -pipe" # XXX not yet supported: -fstack-protector-strong
XBPS_CXXFLAGS="$XBPS_CFLAGS"
XBPS_CROSS_CFLAGS="-march=armv8-a"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="aarch64-unknown-linux-gnu"
