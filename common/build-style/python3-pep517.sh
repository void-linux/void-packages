#
# This style is for templates installing python3 modules adhering to PEP517
#

do_build() {
	# No PEP517 build tool currently supports compiled extensions
	# Thus, there is no need to accommodate cross compilation here
	: ${make_build_target:=.}

	mkdir -p build
	TMPDIR=build python3 -m pip wheel --no-deps --use-pep517 --no-clean \
		--no-build-isolation ${make_build_args} ${make_build_target}
}

do_check() {
	if python3 -c 'import pytest' >/dev/null 2>&1; then
		python3 -m pytest ${make_check_args} ${make_check_target}
	else
		msg_warn "Unable to determine tests for PEP517 Python templates"
		return 0
	fi
}

do_install() {
	# As with do_build, no need to accommodate cross compilation here
	: ${make_install_target:=${pkgname#python3-}-${version}-*-*-*.whl}

	# If do_build was overridden, make sure the TMPDIR exists
	mkdir -p build
	TMPDIR=build python3 -m pip install --use-pep517 --prefix /usr \
		--root ${DESTDIR} --no-deps --no-build-isolation \
		--no-clean ${make_install_args} ${make_install_target}
}
