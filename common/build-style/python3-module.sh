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
		env CC="$CC" LDSHARED="$LDSHARED" \
			PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
			LDFLAGS="$LDFLAGS" python3 setup.py build ${make_build_args}
	else
		python3 setup.py build ${make_build_args}
	fi
}

do_check() {
	local _default_target=test

	if [ -z "$make_check_target" ]; then
		if ! python3 setup.py --help ${_default_target} >/dev/null 2>&1; then
			msg_warn "No command '${_default_target}' defined by setup.py.\n"
			return 0
		fi
	fi

	: ${make_check_target:=${_default_target}}
	python3 setup.py ${make_check_target} ${make_check_args}
}

do_install() {
	if [ -n "$CROSS_BUILD" ]; then
		PYPREFIX="$XBPS_CROSS_BASE"
		CFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_inc} -I${XBPS_CROSS_BASE}/usr/include"
		LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_lib} -L${XBPS_CROSS_BASE}/usr/lib"
		CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
		LDSHARED="${CC} -shared $LDFLAGS"
		env CC="$CC" LDSHARED="$LDSHARED" \
			PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
			LDFLAGS="$LDFLAGS" python3 setup.py \
				install --prefix=/usr --root=${DESTDIR} ${make_install_args}
	else
		python3 setup.py install --prefix=/usr --root=${DESTDIR} ${make_install_args}
	fi
}
