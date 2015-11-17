# Enable SSP and FORITFY_SOURCE=2 by default.
XBPS_CFLAGS+=" -fstack-protector-strong -D_FORTIFY_SOURCE=2"
XBPS_CXXFLAGS+=" ${XBPS_CFLAGS}"
# Enable as-needed and relro by default.
XBPS_LDFLAGS+=" -Wl,--as-needed -Wl,-z,relro"

if [ -z "$nopie" ]; then
	_GCCSPECSDIR=${XBPS_COMMONDIR}/environment/configure/gccspecs
	XBPS_CFLAGS+=" -specs=${_GCCSPECSDIR}/hardened-cc1"
	XBPS_CXXFLAGS+=" -specs=${_GCCSPECSDIR}/hardened-cc1"
	# We pass -z relro -z now here too, because libtool drops -specs...
	XBPS_LDFLAGS+=" -specs=${_GCCSPECSDIR}/hardened-ld -Wl,-z,relro -Wl,-z,now"
fi
