#
# This helper is for templates installing python3-only modules.
#

do_build() {
	if [ -n "$CROSS_BUILD" ]; then
		PYPREFIX="$XBPS_CROSS_BASE"
		CFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_inc} -I${XBPS_CROSS_BASE}/usr/include"
		LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_lib} -L${XBPS_CROSS_BASE}/usr/lib"
		CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
		LDSHARED="${CC} -shared $LDFLAGS"
		for f in ${XBPS_CROSS_BASE}/${py3_lib}/_sysconfigdata_*; do
			f=${f##*/}
			_PYTHON_SYSCONFIGDATA_NAME=${f%.py}
		done
		env CC="$CC" LDSHARED="$LDSHARED" \
			PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
			PYTHONPATH=${XBPS_CROSS_BASE}/${py3_lib} \
			_PYTHON_SYSCONFIGDATA_NAME="$_PYTHON_SYSCONFIGDATA_NAME" \
			LDFLAGS="$LDFLAGS" python3 setup.py build ${make_build_args}
	else
		python3 setup.py build ${make_build_args}
	fi
}

do_check() {
	if python3 -c 'import pytest' >/dev/null 2>&1; then
		PYTHONPATH="$(cd build/lib* && pwd)" \
			${make_check_pre} \
			python3 -m pytest ${make_check_args} ${make_check_target}
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
	if [ -n "$CROSS_BUILD" ]; then
		PYPREFIX="$XBPS_CROSS_BASE"
		CFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_inc} -I${XBPS_CROSS_BASE}/usr/include"
		LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_lib} -L${XBPS_CROSS_BASE}/usr/lib"
		CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
		LDSHARED="${CC} -shared $LDFLAGS"
		for f in ${XBPS_CROSS_BASE}/${py3_lib}/_sysconfigdata_*; do
			f=${f##*/}
			_PYTHON_SYSCONFIGDATA_NAME=${f%.py}
		done
		env CC="$CC" LDSHARED="$LDSHARED" \
			PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
			PYTHONPATH=${XBPS_CROSS_BASE}/${py3_lib} \
			_PYTHON_SYSCONFIGDATA_NAME="$_PYTHON_SYSCONFIGDATA_NAME" \
			LDFLAGS="$LDFLAGS" python3 setup.py \
				install --prefix=/usr --root=${DESTDIR} ${make_install_args}
	else
		python3 setup.py install --prefix=/usr --root=${DESTDIR} ${make_install_args}
	fi
}
