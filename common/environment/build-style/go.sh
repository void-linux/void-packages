if [ -z "$hostmakedepends" -o "${hostmakedepends##*gcc-go-tools*}" ]; then
	# gc compiler
	if [ -z "$archs" ]; then
		archs="aarch64* armv[567]* i686* x86_64* ppc64le*"
	fi
	hostmakedepends+=" go"
	nopie=yes
else
	# gccgo compiler
	if [ -z "$archs" ]; then
		# we have support for these in our gcc
		# ppcle is missing, and mips doesn't have go in cross yet
		archs="aarch64* armv[567]* i686* x86_64* ppc64* ppc ppc-musl"
	fi
	if [ "$CROSS_BUILD" ]; then
		# target compiler to use; otherwise it'll just call gccgo
		export GCCGO="${XBPS_CROSS_TRIPLET}-gccgo"
	fi
fi
nostrip=yes

case "$XBPS_TARGET_MACHINE" in
	aarch64*) export GOARCH=arm64;;
	armv5*) export GOARCH=arm; export GOARM=5;;
	armv6*) export GOARCH=arm; export GOARM=6;;
	armv7*) export GOARCH=arm; export GOARM=7;;
	i686*) export GOARCH=386;;
	x86_64*) export GOARCH=amd64;;
	ppc64le*) export GOARCH=ppc64le;;
	ppc64*) export GOARCH=ppc64;;
	ppc*) export GOARCH=ppc;;
	mipsel*) export GOARCH=mipsle;;
	mips*) export GOARCH=mips;;
esac

export GOPATH="${wrksrc}/_build-${pkgname}-xbps"
GOSRCPATH="${GOPATH}/src/${go_import_path}"
export CGO_CFLAGS="$CFLAGS"
export CGO_CPPFLAGS="$CPPFLAGS"
export CGO_CXXFLAGS="$CXXFLAGS"
export CGO_LDFLAGS="$LDFLAGS"
export CGO_ENABLED=1
case "$XBPS_TARGET_MACHINE" in
	*-musl) export GOCACHE="${XBPS_HOSTDIR}/gocache-muslc" ;;
	*)	export GOCACHE="${XBPS_HOSTDIR}/gocache-glibc" ;;
esac
