#
# This style is for templates installing python3 modules adhering to PEP517
#

do_build() {
	: ${make_build_target:=.}
	: ${make_build_args:=--no-isolation  --wheel}
	python3 -m build ${make_build_args} ${make_build_target}
}

do_check() {
	: ${make_install_target:="dist/*.whl"}

	local testjobs
	if python3 -c 'import pytest' >/dev/null 2>&1; then
		if python3 -c 'import xdist' >/dev/null 2>&1; then
			testjobs="-n $XBPS_MAKEJOBS"
		fi

		local testdir="${wrksrc}/tmp/$(date +%s)"
		python3 -m installer --destdir "${testdir}" \
			${make_install_args} ${make_install_target}

		PATH="${testdir}/usr/bin:${PATH}" PYTHONPATH="${testdir}/${py3_sitelib}" \
			${make_check_pre} pytest3 ${testjobs} ${make_check_args} ${make_check_target}
	else
		msg_warn "Unable to determine tests for PEP517 Python templates\n"
		return 0
	fi
}

do_install() {
	: ${make_install_args:=--no-compile-bytecode}
	: ${make_install_target:="dist/*.whl"}

	python3 -m installer --destdir ${DESTDIR} \
		${make_install_args} ${make_install_target}
}
