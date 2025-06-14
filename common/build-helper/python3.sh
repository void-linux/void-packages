# fix building non-pure-python modules on cross
if [ -n "$CROSS_BUILD" ]; then
	export PYPREFIX="$XBPS_CROSS_BASE"
	export CFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_inc} -I${XBPS_CROSS_BASE}/usr/include"
	export CXXFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_inc} -I${XBPS_CROSS_BASE}/usr/include"
	export LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_lib} -L${XBPS_CROSS_BASE}/usr/lib"
	export CC="${XBPS_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
	export CXX="${XBPS_CROSS_TRIPLET}-g++ -pthread $CXXFLAGS $LDFLAGS"
	export LDSHARED="${CC} -shared $LDFLAGS"
	export PYTHON_CONFIG="${XBPS_CROSS_BASE}/usr/bin/python3-config"
	export PYTHONPATH="${XBPS_CROSS_BASE}/${py3_lib}"
	for f in ${XBPS_CROSS_BASE}/${py3_lib}/_sysconfigdata_*; do
		[ -f "$f" ] || continue
		f=${f##*/}
		_PYTHON_SYSCONFIGDATA_NAME=${f%.py}
	done
	[ -n "$_PYTHON_SYSCONFIGDATA_NAME" ] && export _PYTHON_SYSCONFIGDATA_NAME
fi
