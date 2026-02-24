hostmakedepends+=" cargo"

if ! [[ "$pkgname" =~ ^cargo-auditable(-bootstrap)?$ ]]; then
	hostmakedepends+=" cargo-auditable"
fi

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi

build_helper+=" rust"
