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
