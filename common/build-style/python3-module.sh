#
# This helper is for templates installing python3-only modules.
#

do_build() {
	python3 setup.py build ${make_build_args}
}

do_check() {
	local testjobs
	if python3 -c 'import pytest' >/dev/null 2>&1; then
		if python3 -c 'import xdist' >/dev/null 2>&1; then
			testjobs="-n $XBPS_MAKEJOBS"
		fi
		PYTHONPATH="$(cd build/lib* && pwd)" PY_IGNORE_IMPORTMISMATCH=1 \
			${make_check_pre} \
			python3 -m pytest ${testjobs} ${make_check_args} ${make_check_target}
	else
		# Fall back to deprecated setup.py test orchestration without pytest
		if [ -z "$make_check_target" ]; then
			if ! python3 setup.py --help test >/dev/null 2>&1; then
				msg_warn "No command 'test' defined by setup.py.\n"
				return 0
			fi
		fi

		: ${make_check_target:=test}
		${make_check_pre} python3 setup.py ${make_check_target} ${make_check_args}
	fi
}

do_install() {
	python3 setup.py install --prefix=/usr --root=${DESTDIR} ${make_install_args}
}
