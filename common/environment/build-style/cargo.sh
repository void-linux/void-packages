hostmakedepends+=" cargo"

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi

build_helper+=" rust"
