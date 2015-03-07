_GCCSPECSDIR=${XBPS_COMMONDIR}/environment/configure/gccspecs

if [ -n "$build_pie" ]; then
	CFLAGS+=" -specs=$_GCCSPECSDIR/hardened-cc1"
	LDFLAGS+=" -specs=$_GCCSPECSDIR/hardened-ld"
fi
