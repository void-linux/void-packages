hostmakedepends+=" cargo"

if [ "$CROSS_BUILD" ]; then
	makedepends+=" rust-std"
fi
