# This file sets up configure_args with common settings.

if [ -z "$build_style" -o "$build_style" = "gnu-configure" ]; then
	configure_args="--prefix=/usr --sysconfdir=/etc --infodir=/usr/share/info --mandir=/usr/share/man --localstatedir=/var ${configure_args}"
fi


# Cross compilation vars
if [ -z "$CROSS_BUILD" ]; then
	return 0
fi

configure_args+=" --host=$XBPS_CROSS_TRIPLET --with-sysroot=$XBPS_CROSS_BASE --with-libtool-sysroot=$XBPS_CROSS_BASE "

if [ "$build_style" != "gnu-configure" ]; then
	return 0
fi

_AUTOCONFCACHEDIR=${XBPS_COMMONDIR}/environment/configure/autoconf_cache

# Read autoconf cache variables for cross target (taken from OE).
case "$XBPS_TARGET_MACHINE" in
	# musl libc
	*-musl) . ${_AUTOCONFCACHEDIR}/common-linux
		;;
	# gnu libc
	*)	. ${_AUTOCONFCACHEDIR}/common-glibc
		;;
esac

# Read apropiate autoconf cache files for target machine.
case "$XBPS_TARGET_MACHINE" in
	armv?l*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/arm-common
		. ${_AUTOCONFCACHEDIR}/arm-linux
		;;

	i686*)	. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/ix86-common
		;;

	mips)	. ${_AUTOCONFCACHEDIR}/endian-big
		. ${_AUTOCONFCACHEDIR}/mips-common
		. ${_AUTOCONFCACHEDIR}/mips-linux
		;;

	mipsel)	. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/mips-common
		. ${_AUTOCONFCACHEDIR}/mips-linux
		;;

	x86_64*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/x86_64-linux
		;;

	*) ;;
esac

unset _AUTOCONFCACHEDIR
