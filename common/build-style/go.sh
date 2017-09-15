#
# This helper is for templates for Go packages.
#

do_build() {
	local path="${GOPATH}/src/${go_import_path}"
	if [[ "${go_get}" != "yes" ]]; then
		mkdir -p "$(dirname ${path})"
		ln -fs $PWD "${path}"
	fi

	if [[ -x /usr/bin/dep ]]; then
		cd "${path}"
		dep ensure
	fi

	go_package=${go_package:-$go_import_path}
	go get -x -tags "${go_build_tags}" -ldflags "${go_ldflags}" ${go_package}
}

do_install() {
	find "${GOPATH}/bin" -type f -executable | while read line
	do
		vbin "${line}"
	done
}
