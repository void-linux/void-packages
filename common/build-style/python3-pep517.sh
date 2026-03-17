#
# This style is for templates installing python3 modules adhering to PEP517
#

do_build() {
	: ${make_build_target:=.}

	if [ "${CROSS_BUILD}" ] && [[ "${build_helper}" = *meson* ]]; then
		local mcross="-Csetup-args=--cross-file=${XBPS_WRAPPERDIR}/meson"
		make_build_args+=" ${mcross}/xbps_meson.cross"

		if [[ "${build_helper}" = *numpy* ]]; then
			make_build_args+=" ${mcross}/xbps_numpy.cross"
		fi
	fi

	python3 -m build --no-isolation --wheel \
		${make_build_args} ${make_build_target}
}

do_check() {
	if ! python3 -c 'import pytest' >/dev/null 2>&1; then
		msg_warn "Testing of python3-pep517 templates requires pytest\n"
		return 0
	fi

	local testjobs
	if python3 -c 'import xdist' >/dev/null 2>&1; then
		testjobs="-n $XBPS_MAKEJOBS"
	fi

	local testdir="${wrksrc}/.xbps-testdir/$(date +%s)"
	python3 -m installer --destdir "${testdir}" \
		${make_install_args} ${make_install_target:-dist/*.whl}

	PATH="${testdir}/usr/bin:${PATH}" PYTHONPATH="${testdir}/${py3_sitelib}" PY_IGNORE_IMPORTMISMATCH=1 \
		${make_check_pre} pytest3 ${testjobs} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_install_args:=--no-compile-bytecode}
	: ${make_install_target:="dist/*.whl"}

	python3 -m installer --destdir ${DESTDIR} \
		${make_install_args} ${make_install_target}
}
