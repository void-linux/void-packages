#!/bin/sh
#
# Script to be able to build a full cross toolchain for Linux/x86.
# This has been made thanks to various sources recollected from wikipedia
# and other cross compiling related pages.

# Setup some defaults
: ${GNU_URL_BASE:=http://ftp.gnu.org/gnu}
: ${KERNEL_URL_BASE:=http://www.kernel.org/pub/linux/kernel/v2.6}

: ${GCC_VER:=4.3.2}
: ${BINUTILS_VER:=2.19}
: ${GLIBC_VER:=2.7}
: ${KERNEL_VER:=2.6.27.3}

: ${CROSSDIR:=$HOME/mktoolchain}
: ${BUILDDIR:=$CROSSDIR/build}
: ${SOURCEDISTDIR:=$BUILDDIR/sources}

: ${FETCH_CMD:=wget}

usage()
{
	echo "usage: $0 [-b dir] [-c dir] [-s dir] <target triplet>"
	echo
	echo "Optional flags:"
	echo "	-b	Directory to be used for temporary building."
	echo "	-c	Directory to be used for final cross tools."
	echo "	-s	Directory where the sources are available."
	exit 1
}

check_path()
{
	local orig="$1"

	case "$orig" in
		/) ;;
		/*) orig="${orig%/}" ;;
		*) orig="$PWD/${orig%/}" ;;
	esac

	SANITIZED_DESTDIR=$orig
}

fetch_sources()
{
	local pkg=
	cd $SOURCEDISTDIR || exit 1

	pkg=linux
	if [ ! -f $pkg-$KERNEL_VER.tar.bz2 ]; then
		echo "Fetching $pkg kernel-$KERNEL_VER sources..."
		$FETCH_CMD $KERNEL_URL_BASE/$pkg-$KERNEL_VER.tar.bz2 || exit 1
	fi

	pkg=gcc
	if [ ! -f $pkg-$GCC_VER.tar.bz2 ]; then
		echo "Fetching $pkg-$GCC_VER..."
		$FETCH_CMD $GNU_URL_BASE/$pkg/$pkg-$GCC_VER.tar.bz2 || exit 1
	fi

	pkg=binutils
	if [ ! -f $pkg-$BINUTILS_VER.tar.bz2 ]; then
		echo "Fetching $pkg-$BINUTILS_VER..."
		$FETCH_CMD $GNU_URL_BASE/$pkg/$pkg-$BINUTILS_VER.tar.bz2 \
			|| exit 1
	fi

	pkg=glibc
	if [ ! -f $pkg-$GLIBC_VER.tar.bz2 ]; then
		echo "Fetching $pkg-$GLIBC_VER..."
		$FETCH_CMD $GNU_URL_BASE/$pkg/$pkg-$GLIBC_VER.tar.bz2 || exit 1
	fi
}

kernel_headers()
{
	local pkg="linux-$KERNEL_VER"

	cd $BUILDDIR || exit 1

	tar xfj $SOURCEDISTDIR/$pkg.tar.bz2 -C $BUILDDIR || exit 1
	cd $pkg || exit 1
	make ARCH=$KERNEL_ARCH headers_check || exit 1
	make ARCH=$KERNEL_ARCH headers_install \
		INSTALL_HDR_PATH=$SYSROOT/usr || exit 1
	cd $SYSROOT/usr/include && ln -s asm asm-$KERNEL_ARCH
	cd $BUILDDIR && rm -rf $pkg || exit 1

	touch -f $BUILDDIR/.kernel_headers_done
}

binutils()
{
	local pkg="binutils-$BINUTILS_VER"

	cd $BUILDDIR || exit 1

	if [ ! -d $pkg ]; then
		tar xfj $SOURCEDISTDIR/$pkg.tar.bz2 -C $BUILDDIR || exit 1
	fi

	cd $pkg || exit 1
	[ ! -d build ] && mkdir build || exit 1
	cd build || exit 1

	../configure --prefix=$CROSSDIR		\
		--target=$CROSS_TARGET		\
		--with-sysroot=$SYSROOT		\
		--with-build-sysroot=$SYSROOT	\
		--disable-nls --enable-shared	\
		--disable-multilib || exit 1

	make configure-host && make && make install || exit 1

	# Remove unneeded stuff
	for f in info man share; do
		[ -d $CROSSDIR/$f ] && rm -rf $CROSSDIR/$f
	done

	cd $BUILDDIR && rm -rf $pkg || exit 1

	touch -f $BUILDDIR/.binutils_done
}

glibc_patches()
{
	# Apply some required patches for i[56]86-pc-linux-gnu and
	# common targets.
	$FETCH_CMD http://www.freesa.org/toolchain/patches/glibc-2.7-fixup_for_gcc43-1.patch
	$FETCH_CMD http://www.freesa.org/toolchain/patches/glibc-2.7-i586_chk-1.patch
	$FETCH_CMD http://www.freesa.org/toolchain/patches/glibc-2.7-libgcc_eh-1.patch
	$FETCH_CMD http://svn.exactcode.de/t2/trunk/package/base/glibc/x86-fnstsw.patch

	patch -Np1 -i glibc-2.7-fixup_for_gcc43-1.patch || exit 1
	patch -Np1 -i glibc-2.7-i586_chk-1.patch || exit 1
	patch -Np1 -i glibc-2.7-libgcc_eh-1.patch || exit 1
	patch -Np1 -i x86-fnstsw.patch || exit 1

	touch -f $BUILDDIR/glibc-$GLIBC_VER/.patches_done
}

gcc()
{
	local stage="$1"
	local pkg="gcc-$GCC_VER"
	local configure_args=
	local make_args=
	local make_install_args=
	local touch_f=

	cd $BUILDDIR || exit 1

	if [ ! -d $pkg ]; then
		tar xfj $SOURCEDISTDIR/$pkg.tar.bz2 -C $BUILDDIR || exit 1
	fi

	[ ! -d $pkg/build ] && mkdir $pkg/build

	cd $pkg/build || exit 1

	case $stage in
	full)
		# gcc with support for C and C++.
		touch_f=".gcc_full_done"
		make_args="AS_FOR_TARGET=$CROSS_TARGET-as"
		make_args="$make_args LD_FOR_TARGET=$CROSS_TARGET-ld"
		make_install_args="install"
		configure_args="--enable-threads=posix"
		configure_args="$configure_args --enable-languages=c,c++"
		configure_args="$configure_args --enable-__cxa_atexit"
		configure_args="$configure_args --enable-tls"
		;;
	libgcc)
		# Enough to be able to build full glibc.
		make all-target-libgcc && make install-target-libgcc || exit 1
		rm -rf $SYSROOT/lib/crt* || exit 1
		touch -f $BUILDDIR/.gcc_libgcc_done
		cd $BUILDDIR/$pkg && rm -rf build
		return 0
		;;
	bootstrap)
		# gcc bootstrap
		touch_f=".gcc_bootstrap_done"
		make_args="all-gcc"
		make_install_args="install-gcc"
		configure_args="--disable-shared --disable-libmudflap"
		configure_args="$configure_args --disable-threads"
		configure_args="$configure_args --disable-libssp"
		configure_args="$configure_args --enable-languages=c"
		;;
	*)	;;
	esac

	../configure --prefix=$CROSSDIR				\
		--build=$CROSS_HOST --host=$CROSS_HOST		\
		--target=$CROSS_TARGET				\
		--with-sysroot=$SYSROOT				\
		--with-build-sysroot=$SYSROOT			\
		--disable-multilib				\
		${configure_args} || exit 1

	env LDFLAGS_FOR_TARGET="--sysroot=$SYSROOT"		\
	    CPPFLAGS_FOR_TARGET="--sysroot=$SYSROOT"		\
		make ${make_args} && make ${make_install_args} || exit 1

	# Remove unneeded stuff
	for f in info share man; do
		[ -d $CROSSDIR/$f ] && rm -rf $CROSSDIR/$f
	done

	# Do not remove builddir if bootstrap, we want all objs for
	# the libgcc pass.
	if [ "$stage" != "bootstrap" ]; then
		cd $BUILDDIR/$pkg && rm -rf build || exit 1
	fi

	touch -f $BUILDDIR/$touch_f
}

glibc()
{
	local stage="$1"
	local pkg="glibc-$GLIBC_VER"
	local touch_f=
	local cross_binutils="$CROSSDIR/$CROSS_TARGET/bin"
	local configure_args=
	local CC=
	local BUILD_CC=
	local RANLIB=
	local AR=

	cd $BUILDDIR || exit 1

	if [ ! -d $pkg ]; then
		tar xfj $SOURCEDISTDIR/$pkg.tar.bz2 -C $BUILDDIR || exit 1
	fi

	cd $pkg || exit 1
	[ ! -f .patches_done ] && glibc_patches
	[ ! -d build ] && mkdir build
	cd build || exit 1

	# NPTL support.
	echo "libc_cv_forced_unwind=yes" > config.cache
	echo "libc_cv_c_cleanup=yes" >> config.cache
	if [ "$KERNEL_ARCH" = "i386" ]; then
		echo "CFLAGS+=-march=${CROSS_TARGET%%-*} -mtune=generic" \
			> configparms
	fi

	case $stage in
	startup|full)
		BUILD_CC=$CROSS_TARGET-gcc
		CC=$CROSS_TARGET-gcc
		AR=$CROSS_TARGET-ar
		RANLIB=$CROSS_TARGET-ranlib
		configure_args="${configure_args} --with-binutils=$CROSSDIR/bin"
		configure_args="${configure_args} --cache-file=config.cache"
		;;
	headers)
		CC=gcc
		configure_args="${configure_args} --with-binutils=$cross_binutils"
		configure_args="${configure_args} --disable-sanity-checks"
		;;
	*)	;;
	esac

	CC=${CC} BUILD_CC=${BUILD_CC} AR=${AR} RANLIB=${RANLIB}	\
		../configure --prefix=/usr			\
		--host=$CROSS_TARGET --build=$CROSS_HOST	\
		--enable-kernel=2.6.25 --with-tls		\
		--with-__thread --without-selinux		\
		--without-gd --without-cvs --disable-profile	\
		--enable-add-ons				\
		--with-headers=$SYSROOT/usr/include		\
		${configure_args} || exit 1

	case $stage in
	startup)
		touch_f=".glibc_startup_done"
		make -r -C ../csu objdir=$PWD $PWD/csu/crt1.o || exit 1
		make -r -C ../csu objdir=$PWD $PWD/csu/crti.o || exit 1
		make -r -C ../csu objdir=$PWD $PWD/csu/crtn.o || exit 1
		mkdir -p $SYSROOT/lib || exit 1
		cp -f csu/crt1.o csu/crti.o csu/crtn.o $SYSROOT/lib || exit 1
		;;
	headers)
		touch_f=".glibc_headers_done"
		make cross-compiling=yes \
			install_root=$SYSROOT install-headers || exit 1
		cp -v bits/stdio_lim.h $SYSROOT/usr/include/bits || exit 1
		touch $SYSROOT/usr/include/gnu/stubs.h || exit 1
		cp -v ../nptl/sysdeps/pthread/pthread.h \
			$SYSROOT/usr/include || exit 1
		if [ "$KERNEL_ARCH" = "i386" ]; then
			local bitsdir="nptl/sysdeps/unix/sysv/linux/i386/bits"
			cp -v ../$bitsdir/pthreadtypes.h \
				$SYSROOT/usr/include/bits || exit 1
		fi
		;;
	full)
		touch_f=".glibc_full_done"
		make && make install_root=$SYSROOT install || exit 1
		;;
	esac

	if [ "$stage" != "headers" ]; then
		cd $BUILDDIR/$pkg && rm -rf build || exit 1
	fi

	touch -f $BUILDDIR/$touch_f
}

while getopts "b:c:s:" opt; do
	case $opt in
	b)	BUILDDIR=$OPTARG
		check_path $BUILDDIR
		BUILDDIR=$SANITIZED_DESTDIR
		;;
	c)	CROSSDIR=$OPTARG
		check_path $CROSSDIR
		CROSSDIR=$SANITIZED_DESTDIR
		;;
	s)	SOURCEDISTDIR=$OPTARG
		check_path $SOURCEDISTDIR
		SOURCEDISTDIR=$SANITIZED_DESTDIR
		;;
	--)	shift; break;;
	esac
done
shift $(($OPTIND - 1))

[ $# -ne 1 ] && usage

if [ -z "$1" ]; then
	echo "ERROR: missing target triplet."
	exit 1
else
	CROSS_TARGET=$1
	case $CROSS_TARGET in
		i686-pc-linux-gnu)
			KERNEL_ARCH=i386
			CROSS_HOST=x86_64-unknown-linux-gnu
			;;
		x86-64-unknown-linux-gnu)
			KERNEL_ARCH=x86_64
			CROSS_HOST=i686-pc-linux-gnu
			;;
		*)
			echo "ERROR: unknown target triplet $CROSS_TARGET."
			exit 1
			;;
	esac
fi

CROSSDIR=$CROSSDIR/$CROSS_TARGET
SYSROOT=$CROSSDIR/sysroot
[ ! -d $SYSROOT/usr ] && mkdir -p $SYSROOT/usr
[ ! -d $BUILDDIR ] && mkdir -p $BUILDDIR
[ ! -d $SOURCEDISTDIR ] && mkdir -p $SOURCEDISTDIR

unset CFLAGS CXXFLAGS CC CXX AR AS RANLIB LD_STRIP
unset LD_LIBRARY_PATH LD_RUN_PATH
export PATH="$CROSSDIR/bin:/bin:/usr/bin"

fetch_sources

if [ ! -f $BUILDDIR/.kernel_headers_done ]; then
	echo "Installing kernel headers..."
	kernel_headers
fi

if [ ! -f $BUILDDIR/.binutils_done ]; then
	echo "Installing binutils..."
	binutils
fi

if [ ! -f $BUILDDIR/.glibc_headers_done ]; then
	echo "Installing glibc headers..."
	glibc headers
fi

if [ ! -f $BUILDDIR/.gcc_bootstrap_done ]; then
	echo "Installing gcc (bootstrap)..."
	gcc bootstrap
fi

if [ ! -f $BUILDDIR/.glibc_startup_done ]; then
	echo "Installing glibc (startup)..."
	glibc startup
fi

if [ ! -f $BUILDDIR/.gcc_libgcc_done ]; then
	echo "Installing gcc (libgcc)..."
	gcc libgcc
fi

if [ ! -f $BUILDDIR/.glibc_full_done ]; then
	echo "Installing glibc (full)..."
	glibc full
fi

if [ ! -f $BUILDDIR/.gcc_full_done ]; then
	echo "Installing gcc (full)..."
	gcc full
fi

[ -d $BUILDDIR ] && rm -rf $BUILDDIR

echo "Finished. Toolchain for $CROSS_TARGET at $CROSSDIR."

exit 0
