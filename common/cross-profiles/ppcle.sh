# Cross build profile for little endian PowerPC.

XBPS_TARGET_MACHINE="ppcle"
XBPS_TARGET_QEMU_MACHINE="ppcle"
XBPS_CROSS_TRIPLET="powerpcle-linux-gnu"
XBPS_CROSS_CFLAGS="-mcpu=power8 -mtune=power9"
XBPS_CROSS_CXXFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_FFLAGS="$XBPS_CROSS_CFLAGS"
XBPS_CROSS_RUSTFLAGS="--sysroot=${XBPS_CROSS_BASE}/usr"
XBPS_CROSS_RUST_TARGET="powerpcle-unknown-linux-gnu"
XBPS_CROSS_ZIG_TARGET="powerpcle-linux-gnu"
XBPS_CROSS_ZIG_CPU="pwr8"
