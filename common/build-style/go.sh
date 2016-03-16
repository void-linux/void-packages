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
	go get -x -tags "${go_build_tags}" ${go_package}
}

do_install() {
	find "${GOPATH}/bin" -type f -executable | while read line
	do
		vbin "${line}"
	done
}
