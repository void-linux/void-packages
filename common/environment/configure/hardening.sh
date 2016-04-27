# Enable SSP and FORITFY_SOURCE=2 by default.
_CFLAGS=" -fstack-protector-strong -D_FORTIFY_SOURCE=2 ${CFLAGS}"
_CXXFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 ${CXXFLAGS}"
# Enable as-needed and relro by default.
_LDFLAGS="-Wl,--as-needed ${LDFLAGS}"

case "$XBPS_TARGET_MACHINE" in
	i686-musl) # SSP currently broken (see https://github.com/voidlinux/void-packages/issues/2902)
		_CFLAGS+=" -fno-stack-protector"
		_CXXFLAGS+=" -fno-stack-protector"
		;;
esac

if [ -z "$nopie" ]; then
	_GCCSPECSDIR=${XBPS_COMMONDIR}/environment/configure/gccspecs
	case "$XBPS_TARGET_MACHINE" in
		mips*) _GCCSPECSFILE=${_GCCSPECSDIR}/hardened-mips-cc1;;
		*) _GCCSPECSFILE=${_GCCSPECSDIR}/hardened-cc1;;
	esac
	CFLAGS="-specs=${_GCCSPECSFILE} ${_CFLAGS}"
	CXXFLAGS="-specs=${_GCCSPECSFILE} ${_CXXFLAGS}"
	# We pass -z relro -z now here too, because libtool drops -specs...
	LDFLAGS="-specs=${_GCCSPECSDIR}/hardened-ld -Wl,-z,relro -Wl,-z,now ${_LDFLAGS}"
fi

unset _CFLAGS _CXXFLAGS _LDFLAGS
