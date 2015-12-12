# Enable SSP and FORITFY_SOURCE=2 by default.
CFLAGS=" -fstack-protector-strong -D_FORTIFY_SOURCE=2 $CFLAGS"
CXXFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 $CXXFLAGS"
# Enable as-needed and relro by default.
LDFLAGS="-Wl,--as-needed -Wl,-z,relro $LDFLAGS"

case "$XBPS_TARGET_MACHINE" in
	i686-musl) # SSP currently broken (see https://github.com/voidlinux/void-packages/issues/2902)
		CFLAGS+=" -fno-stack-protector"
		CXXFLAGS+=" -fno-stack-protector"
		;;
	mips-musl|mipsel-musl) # PIE support broken
		unset nopie
		;;
esac

if [ -z "$nopie" ]; then
	_GCCSPECSDIR=${XBPS_COMMONDIR}/environment/configure/gccspecs
	CFLAGS="-specs=${_GCCSPECSDIR}/hardened-cc1 $CFLAGS"
	CXXFLAGS="-specs=${_GCCSPECSDIR}/hardened-cc1 $CXXFLAGS"
	# We pass -z relro -z now here too, because libtool drops -specs...
	LDFLAGS="-specs=${_GCCSPECSDIR}/hardened-ld -Wl,-z,relro -Wl,-z,now $LDFLAGS"
fi
