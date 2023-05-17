hostmakedepends+=" cargo"

if ! [[ "$pkgname" =~ ^cargo-auditable(-bootstrap)?$ ]]; then
	hostmakedepends+=" cargo-auditable"
fi

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi

export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

build_helper+=" rust"
