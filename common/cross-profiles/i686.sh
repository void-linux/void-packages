# Cross build profile for i686 GNU.

XBPS_TARGET_MACHINE="i686"
XBPS_CROSS_TRIPLET="i686-pc-linux-gnu"
XBPS_CROSS_CFLAGS="-march=i686"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="i686-unknown-linux-gnu"
