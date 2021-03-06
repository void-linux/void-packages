# Define equivalent of TOML config in environment
# [build]
# jobs = $XBPS_MAKEJOBS
export CARGO_BUILD_JOBS="$XBPS_MAKEJOBS"
export CARGO_HOME="/host/cargo"

if [ "$CROSS_BUILD" ]; then
	# Define equivalent of TOML config in environment
	# [target.${RUST_TARGET}]
	# linker = ${CC}
	_XBPS_CROSS_RUST_TARGET_ENV="${XBPS_CROSS_RUST_TARGET^^}"
	_XBPS_CROSS_RUST_TARGET_ENV="${_XBPS_CROSS_RUST_TARGET_ENV//-/_}"
	export CARGO_TARGET_${_XBPS_CROSS_RUST_TARGET_ENV}_LINKER="$CC"
	unset _XBPS_CROSS_RUST_TARGET_ENV
	
	# Define equivalent of TOML config in environment
	# [build]
	# target = ${RUST_TARGET}
	export CARGO_BUILD_TARGET="$RUST_TARGET"

	# If cc-rs needs to build host binaries, it guesses the compiler and
	# uses default (wrong) flags unless they are specified explicitly;
	# innocuous flags are used here just to disable its defaults
	export HOST_CC="gcc"
	export HOST_CFLAGS="-O2"
else
	unset CARGO_BUILD_TARGET
fi

# For cross-compiling rust -sys crates
export PKG_CONFIG_ALLOW_CROSS=1

# gettext-rs
export GETTEXT_BIN_DIR=/usr/bin
export GETTEXT_LIB_DIR="${XBPS_CROSS_BASE}/usr/lib/gettext"
export GETTEXT_INCLUDE_DIR="${XBPS_CROSS_BASE}/usr/include"

# libssh2-sys
export LIBSSH2_SYS_USE_PKG_CONFIG=1 

# sodium-sys
export SODIUM_LIB_DIR="${XBPS_CROSS_BASE}/usr/include"
export SODIUM_INC_DIR="${XBPS_CROSS_BASE}/usr/lib"

# openssl-sys
export OPENSSL_NO_VENDOR=1

# pcre2-sys, only necessary for musl targets
export PCRE2_SYS_STATIC=0
