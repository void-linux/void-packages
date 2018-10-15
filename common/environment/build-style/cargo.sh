hostmakedepends+=" cargo"

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi

# Use the config we set in do_configure
export CARGO_HOME="$wrksrc/.cargo"

export PKG_CONFIG_ALLOW_CROSS=1
