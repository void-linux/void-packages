#
# This helper is for templates for Go packages.
#

do_build() {
	case "$XBPS_TARGET_MACHINE" in
		armv6*) export GOARCH=arm; export GOARM=6;;
		armv7*) export GOARCH=arm; export GOARM=7;;
		i686*) export GOARCH=386;;
		x86_64*) export GOARCH=amd64;;
	esac

	export GOPATH="$(mktemp -d --tmpdir="${wrksrc}")"

	if [[ "${go_get}" != "yes" ]]; then
		local path="${GOPATH}/src/${go_import_path}"
		mkdir -p "$(dirname ${path})"
		ln -fs $PWD "${path}"
	fi

	go get -d -v "${go_import_path}"
	go build -x "${go_import_path}"
}

do_install() {
	vbin ${pkgname}
}
