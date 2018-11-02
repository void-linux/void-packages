hostmakedepends+=" cargo"

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi

export PKG_CONFIG_ALLOW_CROSS=1
