#
# This style is for templates installing python3 modules adhering to PEP517
#

do_build() {
	# No PEP517 build tool currently supports compiled extensions
	# Thus, there is no need to accommodate cross compilation here
	: ${make_build_target:=.}

	mkdir -p build
	TMPDIR="${PWD}/build" python3 -m pip wheel --no-deps --use-pep517 --no-clean \
		--no-build-isolation ${make_build_args} ${make_build_target}
}

do_check() {
	local testjobs
	if python3 -c 'import pytest' >/dev/null 2>&1; then
		if python3 -c 'import xdist' >/dev/null 2>&1; then
			testjobs="-n $XBPS_MAKEJOBS"
		fi
		${make_check_pre} python3 -m pytest ${testjobs} ${make_check_args} ${make_check_target}
	else
		msg_warn "Unable to determine tests for PEP517 Python templates"
		return 0
	fi
}

do_install() {
	# As with do_build, no need to accommodate cross compilation here
	if [ -z "${make_install_target}" ]; then
		# Default wheel name normalizes hyphens to underscores
		local wheelbase="${pkgname#python3-}"
		make_install_target="${wheelbase//-/_}-${version}-*-*-*.whl"
	fi

	# If do_build was overridden, make sure the TMPDIR exists
	mkdir -p build
	TMPDIR="${PWD}/build" python3 -m pip install --use-pep517 --prefix /usr \
		--root ${DESTDIR} --no-deps --no-build-isolation \
		--no-clean ${make_install_args} ${make_install_target}
}
