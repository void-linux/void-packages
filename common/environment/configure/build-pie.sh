_GCCSPECSDIR=${XBPS_COMMONDIR}/environment/configure/gccspecs

if [ -n "$build_pie" ]; then
	CFLAGS+=" -specs=$_GCCSPECSDIR/hardened-cc1"
	CXXFLAGS+=" -specs=$_GCCSPECSDIR/hardened-cc1"
	# We pass -z relro -z now here too, because libtool drops -specs...
	LDFLAGS+=" -specs=$_GCCSPECSDIR/hardened-ld -Wl,-z,relro -Wl,-z,now"
fi
