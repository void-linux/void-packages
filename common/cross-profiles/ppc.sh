# Cross build profile for PowerPC.

XBPS_TARGET_MACHINE="ppc"
XBPS_TARGET_QEMU_MACHINE="ppc"
XBPS_CROSS_TRIPLET="powerpc-linux-gnu"
XBPS_CROSS_CFLAGS="-mcpu=powerpc -mno-altivec -mtune=G4"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS=""
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="powerpc-unknown-linux-gnu"
