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

	# Crates that use bindgen via build.rs are not cross-aware unless these are set
	export BINDGEN_EXTRA_CLANG_ARGS+=" --sysroot=${XBPS_CROSS_BASE} -I${XBPS_CROSS_BASE}/usr/include"
else
	unset CARGO_BUILD_TARGET
fi

# prevent cargo stripping debug symbols
export CARGO_PROFILE_RELEASE_STRIP=false

# For cross-compiling rust -sys crates
export PKG_CONFIG_ALLOW_CROSS=1

# For cross-compiling pyo3 bindings
export PYO3_CROSS_LIB_DIR="${XBPS_CROSS_BASE}/usr/lib"
export PYO3_CROSS_INCLUDE_DIR="${XBPS_CROSS_BASE}/usr/include"

# gettext-rs
export GETTEXT_BIN_DIR=/usr/bin
export GETTEXT_LIB_DIR="${XBPS_CROSS_BASE}/usr/lib/gettext"
export GETTEXT_INCLUDE_DIR="${XBPS_CROSS_BASE}/usr/include"

# libssh2-sys
export LIBSSH2_SYS_USE_PKG_CONFIG=1

# sodium-sys
export SODIUM_LIB_DIR="${XBPS_CROSS_BASE}/usr/include"
export SODIUM_INC_DIR="${XBPS_CROSS_BASE}/usr/lib"
export SODIUM_SHARED=1

# openssl-sys
export OPENSSL_NO_VENDOR=1

# pcre2-sys, only necessary for musl targets
export PCRE2_SYS_STATIC=0

# zstd-sys
export ZSTD_SYS_USE_PKG_CONFIG=1

# onig-sys
export RUSTONIG_SYSTEM_LIBONIG=1

# libsqlite3-sys
export LIBSQLITE3_SYS_USE_PKG_CONFIG=1

# jemalloc-sys
export JEMALLOC_SYS_WITH_LG_PAGE=16

# libgit2-sys
export LIBGIT2_NO_VENDOR=1

cat > ${XBPS_WRAPPERDIR}/cargo <<'_EOF'
#!/bin/sh
is_auditable() {
	while [ "$#" != 0 ]; do
		case "$1" in
			-*) shift ;;
			auditable) return 0 ;;
			*) return 1 ;;
		esac
	done
}

if ! command -v cargo-auditable >/dev/null || is_auditable "$@"; then
	exec /usr/bin/cargo "$@"
fi
exec /usr/bin/cargo auditable "$@"
_EOF

chmod 755 ${XBPS_WRAPPERDIR}/cargo
