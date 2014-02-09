# This file sets some envvars to allow cross compiling packages.

[ -z "$CROSS_BUILD" ] && return 0

# Export all variables from now on...
set -a

PKG_CONFIG_SYSROOT_DIR="$XBPS_CROSS_BASE"
PKG_CONFIG_PATH="$XBPS_CROSS_BASE/lib/pkgconfig:$XBPS_CROSS_BASE/usr/share/pkgconfig"
PKG_CONFIG_LIBDIR="$XBPS_CROSS_BASE/lib/pkgconfig"

configure_args+=" --host=$XBPS_CROSS_TRIPLET --with-sysroot=$XBPS_CROSS_BASE --with-libtool-sysroot=$XBPS_CROSS_BASE "

if [ -z "$build_style" -o "$build_style" != "gnu-configure" ]; then
	set +a; return 0
fi

# Read autoconf cache variables for cross target (taken from OE).
case "$XBPS_TARGET_MACHINE" in
	# musl libc, empty for now
	*-musl) ;;

	# gnu libc
	*)	. ${XBPS_COMMONDIR}/environment/autoconf_cache/common-glibc
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/common-linux
		;;
esac

# Read apropiate autoconf cache files for target machine.
case "$XBPS_TARGET_MACHINE" in
	armv?l) . ${XBPS_COMMONDIR}/environment/autoconf_cache/endian-little
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/arm-common
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/arm-linux
		;;

	i686)	. ${XBPS_COMMONDIR}/environment/autoconf_cache/endian-little
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/ix86-common
		;;

	mips)	. ${XBPS_COMMONDIR}/environment/autoconf_cache/endian-big
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/mips-common
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/mips-linux
		;;

	mipsel)	. ${XBPS_COMMONDIR}/environment/autoconf_cache/endian-little
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/mips-common
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/mips-linux
		;;

	x86_64)	. ${XBPS_COMMONDIR}/environment/autoconf_cache/endian-little
		. ${XBPS_COMMONDIR}/environment/autoconf_cache/x86_64-linux
		;;

	*) ;;
esac

# until now :-)
set +a
