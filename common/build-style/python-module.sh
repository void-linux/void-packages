#
# This helper is for templates installing python modules.
#

do_build() {
	: ${python_versions:="2.7 $py3_ver"}
	local pyver= tmp_cflags="$CFLAGS" tmp_ldflags="$LDFLAGS"

	for pyver in $python_versions; do
		if [ -n "$CROSS_BUILD" ]; then
			CFLAGS="$tmp_cflags"
			LDFLAGS="$tmp_ldflags"
			ADDENV=

			PYPREFIX="$XBPS_CROSS_BASE"
			CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${pyver} -I${XBPS_CROSS_BASE}/usr/include"
			LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${pyver} -L${XBPS_CROSS_BASE}/usr/lib"
			CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
			LDSHARED="${CC} -shared $LDFLAGS"
			case $pyver in
			3.*)
				for f in ${XBPS_CROSS_BASE}/${py3_lib}/_sysconfigdata_*; do
					f=${f##*/}
					_PYTHON_SYSCONFIGDATA_NAME=${f%.py}
				done
				ADDENV+=" PYTHONPATH=${XBPS_CROSS_BASE}/${py3_lib}"
				ADDENV+=" _PYTHON_SYSCONFIGDATA_NAME="$_PYTHON_SYSCONFIGDATA_NAME""
			esac
			env CC="$CC" LDSHARED="$LDSHARED" $ADDENV \
				PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
				LDFLAGS="$LDFLAGS" python${pyver} setup.py \
					build --build-base=build-${pyver} ${make_build_args}
		else
			python${pyver} setup.py build --build-base=build-${pyver} ${make_build_args}
		fi
	done
}

do_check() {
	: ${python_versions:="2.7 $py3_ver"}

	for pyver in $python_versions; do
		ln -s build-${pyver} build
		if [ -z "$make_check_target" ]; then
			if ! python${pyver} setup.py --help test >/dev/null 2>&1; then
				msg_warn "No command 'test' defined by setup.py for python${pyver}.\n"
				rm build
				return 0
			fi
		fi

		${make_check_pre} python${pyver} setup.py ${make_check_target:-test} ${make_check_args}
		rm build
	done
}

do_install() {
	: ${python_versions:="2.7 $py3_ver"}
	local pyver=

	for pyver in $python_versions; do
		if [ -n "$CROSS_BUILD" ]; then
			ADDENV=
			PYPREFIX="$XBPS_CROSS_BASE"
			CFLAGS+=" -I${XBPS_CROSS_BASE}/include/python${pyver} -I${XBPS_CROSS_BASE}/usr/include"
			LDFLAGS+=" -L${XBPS_CROSS_BASE}/lib/python${pyver} -L${XBPS_CROSS_BASE}/usr/lib"
			CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
			LDSHARED="${CC} -shared $LDFLAGS"
			case $pyver in
			3.*)
				for f in ${XBPS_CROSS_BASE}/${py3_lib}/_sysconfigdata_*; do
					f=${f##*/}
					_PYTHON_SYSCONFIGDATA_NAME=${f%.py}
				done
				ADDENV+=" PYTHONPATH=${XBPS_CROSS_BASE}/${py3_lib}"
				ADDENV+=" _PYTHON_SYSCONFIGDATA_NAME="$_PYTHON_SYSCONFIGDATA_NAME""
			esac
			env CC="$CC" LDSHARED="$LDSHARED" $ADDENV \
				PYPREFIX="$PYPREFIX" CFLAGS="$CFLAGS" \
				LDFLAGS="$LDFLAGS" python${pyver} setup.py \
					build --build-base=build-${pyver} \
					install --prefix=/usr --root=${DESTDIR} ${make_install_args}
		else
			python${pyver} setup.py build --build-base=build-${pyver} \
				install --prefix=/usr --root=${DESTDIR} ${make_install_args}
		fi

		# Rename unversioned scripts to avoid name conflicts.
		if [ -d ${DESTDIR}/usr/bin ]; then
			find ${DESTDIR}/usr/bin -type f ! -name "*[[:digit:]]" | while IFS= read -r f _; do
				mv "${f}" "${f}${pyver%.*}"
				echo "[python-module] Unversioned script renamed to '${f#$DESTDIR}${pyver%.*}'"
			done
		fi
	done
}
