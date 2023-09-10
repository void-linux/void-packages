if [ -z "$hostmakedepends" -o "${hostmakedepends##*gcc-go-tools*}" ]; then
	# gc compiler
	if [ -z "$archs" ]; then
		archs="aarch64* armv[567]* i686* x86_64* ppc64le* riscv64*"
	fi
	hostmakedepends+=" go"
	nopie=yes
else
	# gccgo compiler
	if [ -z "$archs" ]; then
		# we have support for these in our gcc
		archs="aarch64* armv[567]* i686* x86_64* ppc64* riscv64*"
	fi
	if [ "$CROSS_BUILD" ]; then
		# target compiler to use; otherwise it'll just call gccgo
		export GCCGO="${XBPS_CROSS_TRIPLET}-gccgo"
	fi
fi

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
	riscv64*) export GOARCH=riscv64;;
esac

export GOPATH="${wrksrc}/_build-${pkgname}-xbps"
GOSRCPATH="${GOPATH}/src/${go_import_path}"
export CGO_CFLAGS="$CFLAGS"
export CGO_CPPFLAGS="$CPPFLAGS"
export CGO_CXXFLAGS="$CXXFLAGS"
export CGO_LDFLAGS="$LDFLAGS"
export CGO_ENABLED="${CGO_ENABLED:-1}"
export GO111MODULE=auto
export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
export GOPROXY="https://proxy.golang.org,direct"
export GOSUMDB="sum.golang.org"

case "$XBPS_TARGET_MACHINE" in
	*-musl) export GOCACHE="${XBPS_HOSTDIR}/gocache-muslc" ;;
	*)	export GOCACHE="${XBPS_HOSTDIR}/gocache-glibc" ;;
esac

case "$XBPS_TARGET_MACHINE" in
	# https://go.dev/cl/421935
	i686*) export CGO_CFLAGS="$CGO_CFLAGS -fno-stack-protector" ;;
esac
