#
# This helper is for templates for Go packages.
#

do_build() {
	if [[ "${go_get}" != "yes" ]]; then
		local path="${GOPATH}/src/${go_import_path}"
		mkdir -p "$(dirname ${path})"
		ln -fs $PWD "${path}"
	fi

	go_package=${go_package:-$go_import_path}
	cd "${GOPATH}/src/${go_package}"
	go get -d "${go_package}"
	go build -x "${go_package}"
}

do_install() {
	go_package=${go_package:-$go_import_path}
	cd "${GOPATH}/src/${go_package}"
	vbin ${pkgname}
}
