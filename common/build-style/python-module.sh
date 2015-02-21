#
# This helper is for templates installing python modules.
#

do_build() {
	: ${python_versions:=2.7}
	local pyver= pysufx=

	for pyver in $python_versions; do
		if [ -n "$CROSS_BUILD" ]; then
			PYPREFIX="$XBPS_CROSS_BASE"
			if [ "$pyver" != "2.7" ]; then
				pysufx=m
			fi
			CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${pyver}${pysufx} -I${XBPS_CROSS_BASE}/usr/include"
			LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${pyver} -L${XBPS_CROSS_BASE}/usr/lib"
			CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
			LDSHARED="${CC} -shared $LDFLAGS"
			env CC="$CC" LDSHARED="$LDSHARED" \
				PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
				LDFLAGS="$LDFLAGS" python${pyver} setup.py \
					build --build-base=build-${pyver} ${make_build_args}
		else
			python${pyver} setup.py build --build-base=build-${pyver} ${make_build_args}
		fi
	done
}

do_install() {
	: ${python_versions:=2.7}
	local pyver= pysufx=

	for pyver in $python_versions; do
		if [ -n "$CROSS_BUILD" ]; then
			PYPREFIX="$XBPS_CROSS_BASE"
			if [ "$pyver" != "2.7" ]; then
				pysufx=m
			fi
			CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${pyver}${pysufx} -I${XBPS_CROSS_BASE}/usr/include"
			LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${pyver} -L${XBPS_CROSS_BASE}/usr/lib"
			CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
			LDSHARED="${CC} -shared $LDFLAGS"
			env CC="$CC" LDSHARED="$LDSHARED" \
				PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
				LDFLAGS="$LDFLAGS" python${pyver} setup.py \
					build --build-base=build-${pyver} install ${make_install_args}
		else
			python${pyver} setup.py build --build-base=build-${pyver} \
				install --prefix=/usr --root=$DESTDIR ${make_install_args}
		fi
	done
}
