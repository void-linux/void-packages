if [ -n "$CROSS_BUILD" ]; then
	CFLAGS+=" -I${XBPS_CROSS_BASE}/usr/include"
	CXXFLAGS+=" -I${XBPS_CROSS_BASE}/usr/include"
	LDFLAGS+=" -L${XBPS_CROSS_BASE}/usr/lib"
fi
