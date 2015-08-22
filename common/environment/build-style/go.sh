hostmakedepends+=" go"
if [ "$CROSS_BUILD" ]; then
	hostmakedepends+=" go-cross-linux"
fi
nostrip=yes

case "$XBPS_TARGET_MACHINE" in
	armv6*) export GOARCH=arm; export GOARM=6;;
	armv7*) export GOARCH=arm; export GOARM=7;;
	i686*) export GOARCH=386;;
	x86_64*) export GOARCH=amd64;;
esac

export GOPATH="${wrksrc}/_build-${pkgname}-xbps"
