#
# This helper is for templates for Go packages.
#

do_configure() {
	# $go_import_path must be set, or we can't link $PWD into $GOSRCPATH
	# nor build from modules
	if [ -z "$go_import_path" ]; then
		msg_error "\"\$go_import_path\" not set on $pkgname template.\n"
	fi

	# This isn't really configuration, but its needed by packages
	# that do unusual things with the build where the expect to be
	# able to cd into the $GOSRCPATH
	if [ "${go_mod_mode}" != "off" ] && [ -f go.mod ]; then
		# Skip GOPATH symlink for Go modules
		msg_normal "Building $pkgname using Go modules.\n"
	else
		mkdir -p ${GOSRCPATH%/*}/
		ln -fs "$PWD" "${GOSRCPATH}"
	fi
}

do_build() {
	go_package=${go_package:-$go_import_path}
	# Build using Go modules if there's a go.mod file
	if [ "${go_mod_mode}" != "off" ] && [ -f go.mod ]; then
		if [ -z "${go_mod_mode}" ] && [ -d vendor ]; then
			msg_normal "Using vendor dir for $pkgname Go dependencies.\n"
			go_mod_mode=vendor
		elif [ "${go_mod_mode}" = "default" ]; then
			# Allow templates to explicitly opt into the go tool's
			# default behavior.
			go_mod_mode=
		fi
		go install -p "$XBPS_MAKEJOBS" -mod="${go_mod_mode}" -x -tags "${go_build_tags}" -ldflags "${go_ldflags}" ${go_package}
	else
		# Otherwise, build using GOPATH
		go get -p "$XBPS_MAKEJOBS" -x -tags "${go_build_tags}" -ldflags "${go_ldflags}" ${go_package}
	fi
}

do_install() {
	for f in ${GOPATH}/bin/* ${GOPATH}/bin/**/*; do
		if [ -f "$f" ] && [ -x "$f" ]; then
			vbin "$f"
		fi
	done
}
