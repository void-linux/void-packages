XBPS_WORDSIZE=64
XBPS_TARGET_CFLAGS="-mcpu=powerpc64le -mtune=power9 -maltivec -mlong-double-64 -mabi=elfv2"
XBPS_TARGET_CXXFLAGS="$XBPS_TARGET_CFLAGS"
XBPS_TARGET_FFLAGS=""
XBPS_TRIPLET="powerpc64le-unknown-linux-musl"
XBPS_RUST_TARGET="$XBPS_TRIPLET"
