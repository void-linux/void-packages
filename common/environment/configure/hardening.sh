# Enable SSP and FORITFY_SOURCE=2 by default.
CFLAGS=" -fstack-protector-strong -D_FORTIFY_SOURCE=2 $CFLAGS"
CXXFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 $CXXFLAGS"
# Enable as-needed and relro by default.
LDFLAGS="-Wl,--as-needed -Wl,-z,relro $LDFLAGS"

if [ -z "$nopie" ] && [ "$XBPS_TARGET_ARCH" != mipsel-musl ]; then
	_GCCSPECSDIR=${XBPS_COMMONDIR}/environment/configure/gccspecs
	CFLAGS="-specs=${_GCCSPECSDIR}/hardened-cc1 $CFLAGS"
	CXXFLAGS="-specs=${_GCCSPECSDIR}/hardened-cc1 $CXXFLAGS"
	# We pass -z relro -z now here too, because libtool drops -specs...
	LDFLAGS="-specs=${_GCCSPECSDIR}/hardened-ld -Wl,-z,relro -Wl,-z,now $LDFLAGS"
fi
