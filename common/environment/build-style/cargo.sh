hostmakedepends+=" cargo"

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi

export PKG_CONFIG_ALLOW_CROSS=1

export LIBGIT2_SYS_USE_PKG_CONFIG=1
export GETTEXT_BIN_DIR=/usr/bin
export GETTEXT_LIB_DIR="${XBPS_CROSS_BASE}/usr/lib/gettext"
export GETTEXT_INCLUDE_DIR="${XBPS_CROSS_BASE}/usr/include"
export LIBSSH2_SYS_USE_PKG_CONFIG=1
