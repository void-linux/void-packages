#
# This helper is for templates for Go packages.
#

do_configure() {
	# $go_import_path must be set, or we can't link $PWD into $GOSRCPATH
	if [ -z "$go_import_path" ]; then
		msg_error "\"\$go_import_path\" not set on $pkgname template.\n"
	fi

	# This isn't really configuration, but its needed by packages
	# that do unusual things with the build where the expect to be
	# able to cd into the $GOSRCPATH
	if [[ "${go_get}" != "yes" ]]; then
		mkdir -p "$(dirname ${GOSRCPATH})"
		ln -fs $PWD "${GOSRCPATH}"
	fi
}

do_build() {
	go_package=${go_package:-$go_import_path}
	go get -x -tags "${go_build_tags}" -ldflags "${go_ldflags}" ${go_package}
}

do_install() {
	find "${GOPATH}/bin" -type f -executable | while read line
	do
		vbin "${line}"
	done
}
