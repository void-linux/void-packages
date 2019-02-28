#
# go - helper for packages that use build-style go or go in general
#
#
# - Setups up GOPATH and GOSRCPATH variables
# - provides function to set up GOSRCPATH
# - Sets up CGO configuration
# - Sets up GOCACHE
# - Adds go to hostmakedepends
# - Enables nostrip= and nopie=
# - Sets GOARCH and GOARM for cross compilation
#
export GOPATH="${wrksrc}/_build-${pkgname}-xbps"

export CGO_CFLAGS="$CFLAGS"
export CGO_CPPFLAGS="$CPPFLAGS"
export CGO_CXXFLAGS="$CXXFLAGS"
export CGO_LDFLAGS="$LDFLAGS"
export CGO_ENABLED=1

case "$XBPS_TARGET_MACHINE" in
	*-musl) export GOCACHE="${XBPS_HOSTDIR}/gocache-muslc" ;;
	*)	export GOCACHE="${XBPS_HOSTDIR}/gocache-glibc" ;;
esac

# Useful for projects that need to compile go tools for the
# host system like docker.
case "$XBPS_MACHINE" in
	aarch64*) export HOST_GOARCH=arm64;;
	armv6*) export HOST_GOARCH=arm; export HOST_GOARM=6;;
	armv7*) export HOST_GOARCH=arm; export HOST_GOARM=7;;
	i686*) export HOST_GOARCH=386;;
	x86_64*) export HOST_GOARCH=amd64;;
	ppc64le*) export HOST_GOARCH=ppc64le;;
	ppc64*) export HOST_GOARCH=ppc64;;
esac

case "$XBPS_TARGET_MACHINE" in
	aarch64*) export GOARCH=arm64;;
	armv6*) export GOARCH=arm; export GOARM=6;;
	armv7*) export GOARCH=arm; export GOARM=7;;
	i686*) export GOARCH=386;;
	x86_64*) export GOARCH=amd64;;
	ppc64le*) export GOARCH=ppc64le;;
	ppc64*) export GOARCH=ppc64;;
esac

# This function creates the GOPATH
# it is expected that this function is run during
# do-patch or do-configure.
go:make-gopath() {
	# $go_import_path must be set, or we can't link $PWD into $GOSRCPATH
	# nor build from modules
	if [ -z "$go_import_path" ]; then
		msg_error "\"\$go_import_path\" not set on $pkgname template.\n"
	fi

	GOSRCPATH="${GOPATH}/src/${go_import_path}"

	mkdir -p "${GOSRCPATH%/*}"
	ln -fs $PWD "${GOSRCPATH}"
}
