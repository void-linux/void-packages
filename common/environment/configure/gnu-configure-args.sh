# This file sets up configure_args with common settings.

if [ -n "$build_style" -a "$build_style" != "gnu-configure" ]; then
	return 0
fi

# Store args from template so they can be included last and override
# our defaults
TEMPLATE_CONFIGURE_ARGS="${configure_args}"

export configure_args="--prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --bindir=/usr/bin
 --mandir=/usr/share/man --infodir=/usr/share/info --localstatedir=/var"

. ${XBPS_COMMONDIR}/build-profiles/${XBPS_MACHINE}.sh
export configure_args+=" --host=$XBPS_TRIPLET --build=$XBPS_TRIPLET"

# Always use wordsize-specific libdir even though the real path is lib
# This is to make sure 32-bit and 64-bit libs can coexist when looking
# up things (the opposite-libdir is always symlinked as libNN)
export configure_args+=" --libdir=\${exec_prefix}/lib${XBPS_TARGET_WORDSIZE}"

_AUTOCONFCACHEDIR=${XBPS_COMMONDIR}/environment/configure/autoconf_cache

# From now on all vars are exported to the environment
set -a

# Read autoconf cache variables for native target.
case "$XBPS_TARGET_MACHINE" in
	# musl libc
	*-musl) . ${_AUTOCONFCACHEDIR}/musl-linux
		;;
esac

# Cross compilation vars
if [ -z "$CROSS_BUILD" ]; then
	export configure_args+=" ${TEMPLATE_CONFIGURE_ARGS}"
	unset TEMPLATE_CONFIGURE_ARGS

	set +a
	return 0
fi

export configure_args+=" --host=$XBPS_CROSS_TRIPLET --with-sysroot=$XBPS_CROSS_BASE --with-libtool-sysroot=$XBPS_CROSS_BASE "

export configure_args+=" ${TEMPLATE_CONFIGURE_ARGS}"
unset TEMPLATE_CONFIGURE_ARGS

# Read autoconf cache variables for cross target (taken from OE).
case "$XBPS_TARGET_MACHINE" in
	# musl libc
	*-musl) . ${_AUTOCONFCACHEDIR}/common-linux
		. ${_AUTOCONFCACHEDIR}/musl-linux
		;;
	# gnu libc
	*)	. ${_AUTOCONFCACHEDIR}/common-linux
		. ${_AUTOCONFCACHEDIR}/common-glibc
		;;
esac

# Read apropiate autoconf cache files for target machine.
case "$XBPS_TARGET_MACHINE" in
	armv5te*|armv?l*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/arm-common
		. ${_AUTOCONFCACHEDIR}/arm-linux
		;;

	aarch64*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/aarch64-linux
		;;

	i686*)	. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/ix86-common
		;;

	mips)	. ${_AUTOCONFCACHEDIR}/endian-big
		. ${_AUTOCONFCACHEDIR}/mips-common
		. ${_AUTOCONFCACHEDIR}/mips-linux
		;;

	mipshf*)
		. ${_AUTOCONFCACHEDIR}/endian-big
		. ${_AUTOCONFCACHEDIR}/mips-common
		. ${_AUTOCONFCACHEDIR}/mips-linux
		;;

	mipsel*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/mips-common
		. ${_AUTOCONFCACHEDIR}/mips-linux
		;;

	x86_64*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/x86_64-linux
		;;

	ppc64le*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/powerpc-common
		. ${_AUTOCONFCACHEDIR}/powerpc-linux
		. ${_AUTOCONFCACHEDIR}/powerpc64-linux
		;;

	ppc64*)
		. ${_AUTOCONFCACHEDIR}/endian-big
		. ${_AUTOCONFCACHEDIR}/powerpc-common
		. ${_AUTOCONFCACHEDIR}/powerpc-linux
		. ${_AUTOCONFCACHEDIR}/powerpc64-linux
		;;

	ppcle*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/powerpc-common
		. ${_AUTOCONFCACHEDIR}/powerpc-linux
		. ${_AUTOCONFCACHEDIR}/powerpc32-linux
		;;

	ppc*)
		. ${_AUTOCONFCACHEDIR}/endian-big
		. ${_AUTOCONFCACHEDIR}/powerpc-common
		. ${_AUTOCONFCACHEDIR}/powerpc-linux
		. ${_AUTOCONFCACHEDIR}/powerpc32-linux
		;;
	riscv*)
		. ${_AUTOCONFCACHEDIR}/endian-little
		. ${_AUTOCONFCACHEDIR}/riscv64-linux
		;;

	*) ;;
esac

unset _AUTOCONFCACHEDIR

set +a # vars are not exported to the environment anymore
