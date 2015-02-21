#
# This helper is for templates for Go packages.
#

do_build() {
	if [[ "${go_get}" != "yes" ]]; then
		local path="${GOPATH}/src/${go_import_path}"
		mkdir -p "$(dirname ${path})"
		ln -fs $PWD "${path}"
	fi

	go get -d "${go_import_path}"
	go build -x "${go_import_path}"
}

do_install() {
	vbin ${pkgname}
}
