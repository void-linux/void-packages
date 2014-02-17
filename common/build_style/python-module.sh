#
# This helper is for templates installing python modules.
#
XBPS_PYVER="2.7" # currently 2.7 is the default python

do_build() {
	if [ -n "$CROSS_BUILD" ]; then
		PYPREFIX="$XBPS_CROSS_BASE"
		CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${XBPS_PYVER} -I${XBPS_CROSS_BASE}/usr/include"
		LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${XBPS_PYVER} -L${XBPS_CROSS_BASE}/usr/lib"
		CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
		LDSHARED="${CC} -shared $LDFLAGS"
		env CC="$CC" LDSHARED="$LDSHARED" \
			PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
			LDFLAGS="$LDFLAGS" python setup.py build ${make_build_args}
	else
		python setup.py build ${make_build_args}
	fi
}

do_install() {
	make_install_args+=" --prefix=/usr --root=$DESTDIR"

	if [ -n "$CROSS_BUILD" ]; then
		PYPREFIX="$XBPS_CROSS_BASE"
		CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${XBPS_PYVER} -I${XBPS_CROSS_BASE}/usr/include"
		LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${XBPS_PYVER} -L${XBPS_CROSS_BASE}/usr/lib"
		CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
		LDSHARED="${CC} -shared $LDFLAGS"
		env CC="$CC" LDSHARED="$LDSHARED" \
			PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
			LDFLAGS="$LDFLAGS" python setup.py install ${make_install_args}
	else
		python setup.py install ${make_install_args}
	fi
}
