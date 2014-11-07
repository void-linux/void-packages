#
# This helper is for templates installing python modules.
#

do_build() {
	: ${python_versions:=2.7}
	local python_version= pysufx="m"

	for python_version in $python_versions; do
		if [ -n "$CROSS_BUILD" ]; then
			PYPREFIX="$XBPS_CROSS_BASE"
			if [ "$python_versions" = "2.7" ]; then
				CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${python_version} -I${XBPS_CROSS_BASE}/usr/include"
			else
				CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${python_version}${pysufx} -I${XBPS_CROSS_BASE}/usr/include"
			fi
			LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${python_version} -L${XBPS_CROSS_BASE}/usr/lib"
			CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
			LDSHARED="${CC} -shared $LDFLAGS"
			env CC="$CC" LDSHARED="$LDSHARED" \
				PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
				LDFLAGS="$LDFLAGS" python${python_version} setup.py \
					build --build-base=build-$python_version ${make_build_args}
		else
			python${python_version} setup.py build --build-base=build-$python_version \
				${make_build_args}
		fi
	done
}

do_install() {
	: ${python_versions:=2.7}
	local python_version= pysufx="m"

	make_install_args+=" --prefix=/usr --root=$DESTDIR"

	for python_version in $python_versions; do
		if [ -n "$CROSS_BUILD" ]; then
			PYPREFIX="$XBPS_CROSS_BASE"
			if [ "$python_versions" = "2.7" ]; then
				CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${python_version} -I${XBPS_CROSS_BASE}/usr/include"
			else
				CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${python_version}${pysufx} -I${XBPS_CROSS_BASE}/usr/include"
			fi
			LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${python_version} -L${XBPS_CROSS_BASE}/usr/lib"
			CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
			LDSHARED="${CC} -shared $LDFLAGS"
			env CC="$CC" LDSHARED="$LDSHARED" \
				PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
				LDFLAGS="$LDFLAGS" python${python_version} setup.py \
					build --build-base=build-$python_version install ${make_install_args}
		else
			python${python_version} setup.py build --build-base=build-$python_version install \
				${make_install_args}
		fi
	done
}
