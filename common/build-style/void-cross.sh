#
# This helper is for void system crosstoolchain templates.
#
# Optional variables:
#
# - cross_gcc_skip_go - do not build gccgo support
# - cross_binutils_configure_args
# - cross_gcc_bootstrap_configure_args
# - cross_gcc_configure_args
# - cross_glibc_cflags
# - cross_glibc_ldflags
# - cross_glibc_configure_args
# - cross_musl_cflags
# - cross_musl_ldflags
# - cross_musl_configure_args
#
# configure_args is passed to both bootstrap gcc and final gcc
# if you need to pass some to one and not the other, use the
# respective cross_ variables for final gcc and bootstrap gcc
#

_void_cross_apply_patch() {
	local pname="$(basename $1)"
	if [ ! -f ".${pname}_done" ]; then
		patch -Np1 $args -i $1
		touch .${pname}_done
	fi
}

_void_cross_build_binutils() {
	[ -f ${wrksrc}/.binutils_done ] && return 0

	local tgt=$1
	local ver=$2

	msg_normal "Patching binutils for ${tgt}\n"

	cd ${wrksrc}/binutils-${ver}
	if [ -d "${XBPS_SRCPKGDIR}/binutils/patches" ]; then
		for f in ${XBPS_SRCPKGDIR}/binutils/patches/*.patch; do
			_void_cross_apply_patch "$f"
		done
	fi
	cd ..

	msg_normal "Building binutils for ${tgt}\n"

	mkdir -p ${wrksrc}/binutils_build
	cd ${wrksrc}/binutils_build

	../binutils-${ver}/configure \
		--prefix=/usr \
		--sbindir=/usr/bin \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--target=${tgt} \
		--with-sysroot=/usr/${tgt} \
		--disable-nls \
		--disable-shared \
		--disable-multilib \
		--disable-werror \
		--disable-gold \
		--disable-gprofng \
		--enable-relro \
		--enable-new-dtags \
		--enable-plugins \
		--enable-64-bit-bfd \
		--enable-deterministic-archives \
		--enable-default-hash-style=gnu \
		--with-system-zlib \
		--with-mmap \
		--with-pic \
		${cross_binutils_configure_args}

	make configure-host
	make ${makejobs}

	make install DESTDIR=${wrksrc}/build_root

	touch ${wrksrc}/.binutils_done
}

_void_cross_build_bootstrap_gcc() {
	[ -f ${wrksrc}/.gcc_bootstrap_done ] && return 0

	local tgt=$1
	local ver=$2

	msg_normal "Patching GCC for ${tgt}\n"

	cd ${wrksrc}/gcc-${ver}

	# Do not run fixincludes
	sed -i 's@./fixinc.sh@-c true@' Makefile.in

	for f in ${XBPS_SRCPKGDIR}/gcc/patches/*.patch; do
		_void_cross_apply_patch "$f"
	done
	if [ -f ${wrksrc}/.musl_version ]; then
		for f in ${XBPS_SRCPKGDIR}/gcc/files/*-musl.patch; do
			_void_cross_apply_patch "$f"
		done
	fi
	cd ..

	msg_normal "Building bootstrap GCC for ${tgt}\n"

	mkdir -p gcc_bootstrap
	cd gcc_bootstrap

	local extra_args
	if [ -f ${wrksrc}/.musl_version ]; then
		extra_args+=" --with-newlib"
		extra_args+=" --disable-symvers"
		extra_args+=" libat_cv_have_ifunc=no"
	else
		extra_args+=" --without-headers"
	fi

	../gcc-${ver}/configure \
		--prefix=/usr \
		--sbindir=/usr/bin \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--target=${tgt} \
		--disable-nls \
		--disable-multilib \
		--disable-shared \
		--disable-libquadmath \
		--disable-decimal-float \
		--disable-libgomp \
		--disable-libmpx \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libitm \
		--disable-libatomic --disable-autolink-libatomic \
		--disable-gcov \
		--disable-threads \
		--disable-sjlj-exceptions \
		--enable-languages=c \
		--with-gnu-ld \
		--with-gnu-as \
		${extra_args} \
		${configure_args} \
		${cross_gcc_bootstrap_configure_args}

	make ${makejobs}
	make install DESTDIR=${wrksrc}/build_root

	local ptrs=$(${tgt}-gcc -dM -E - < /dev/null | \
		grep __SIZEOF_POINTER__)
	local ws=${ptrs##* }

	case ${ws} in
		8) echo 64 > ${wrksrc}/.gcc_wordsize ;;
		4) echo 32 > ${wrksrc}/.gcc_wordsize ;;
		*) msg_error "Unknown word size: ${ws}\n" ;;
	esac

	touch ${wrksrc}/.gcc_bootstrap_done
}

_void_cross_build_kernel_headers() {
	[ -f ${wrksrc}/.linux_headers_done ] && return 0

	local tgt=$1
	local ver=$2
	local arch

	msg_normal "Patching Linux headers for ${tgt}\n"

	cd ${wrksrc}/linux-${ver}
	if [ -d "${XBPS_SRCPKGDIR}/kernel-libc-headers/patches" ]; then
		for f in ${XBPS_SRCPKGDIR}/kernel-libc-headers/patches/*.patch; do
			_void_cross_apply_patch "$f"
		done
	fi
	cd ..

	msg_normal "Building Linux headers for ${tgt}\n"

	cd linux-${ver}

	case "$tgt" in
		x86_64*|i686*) arch=x86 ;;
		powerpc*) arch=powerpc ;;
		mips*) arch=mips ;;
		aarch64*) arch=arm64 ;;
		arm*) arch=arm ;;
		riscv*) arch=riscv ;;
		s390*) arch=s390 ;;
		*) msg_error "Unknown Linux arch for ${tgt}\n" ;;
	esac

	make ARCH=${arch} headers
	find usr/include -name '.*' -delete
	rm usr/include/Makefile
	rm -r usr/include/drm
	cp -a usr/include ${wrksrc}/build_root/usr/${tgt}/usr

	touch ${wrksrc}/.linux_headers_done
}

_void_cross_build_glibc_headers() {
	[ -f ${wrksrc}/.glibc_headers_done ] && return 0

	local tgt=$1
	local ver=$2

	msg_normal "Patching glibc for ${tgt}\n"

	cd ${wrksrc}/glibc-${ver}
	if [ -d "${XBPS_SRCPKGDIR}/glibc/patches" ]; then
		for f in ${XBPS_SRCPKGDIR}/glibc/patches/*.patch; do
			_void_cross_apply_patch "$f"
		done
	fi
	cd ..

	msg_normal "Building glibc headers for ${tgt}\n"

	mkdir -p glibc_headers
	cd glibc_headers

	echo "libc_cv_forced_unwind=yes" > config.cache
	echo "libc_cv_c_cleanup=yes" >> config.cache

	# we don't need any custom args here, it's just headers
	CC="${tgt}-gcc" CXX="${tgt}-g++" CPP="${tgt}-cpp" LD="${tgt}-ld" \
	AS="${tgt}-as" NM="${tgt}-nm" CFLAGS="-pipe" CXXFLAGS="" CPPFLAGS="" \
	LDFLAGS="" \
	../glibc-${ver}/configure \
		--prefix=/usr \
		--host=${tgt} \
		--with-headers=${wrksrc}/build_root/usr/${tgt}/usr/include \
		--config-cache \
		--enable-kernel=2.6.27 \
		${cross_glibc_configure_args}

	make -k install-headers cross_compiling=yes \
		install_root=${wrksrc}/build_root/usr/${tgt}

	touch ${wrksrc}/.glibc_headers_done
}

_void_cross_build_glibc() {
	[ -f ${wrksrc}/.glibc_build_done ] && return 0

	local tgt=$1
	local ver=$2

	msg_normal "Building glibc for ${tgt}\n"

	mkdir -p ${wrksrc}/glibc_build
	cd ${wrksrc}/glibc_build

	local ws=$(cat ${wrksrc}/.gcc_wordsize)

	echo "slibdir=/usr/lib${ws}" > configparms

	echo "libc_cv_forced_unwind=yes" > config.cache
	echo "libc_cv_c_cleanup=yes" >> config.cache

	CC="${tgt}-gcc" CXX="${tgt}-g++" CPP="${tgt}-cpp" LD="${tgt}-ld" \
	AR="${tgt}-ar" AS="${tgt}-as" NM="${tgt}-nm" \
	OBJDUMP="${tgt}-objdump" OBJCOPY="${tgt}-objcopy" \
	CFLAGS="-pipe ${cross_glibc_cflags}" \
	CXXFLAGS="-pipe ${cross_glibc_cflags}" \
	CPPFLAGS="" \
	LDFLAGS="${cross_glibc_ldflags}" \
	../glibc-${ver}/configure \
		--prefix=/usr \
		--libdir=/usr/lib${ws} \
		--libexecdir=/usr/libexec \
		--host=${tgt} \
		--with-headers=${wrksrc}/build_root/usr/${tgt}/usr/include \
		--config-cache \
		--disable-profile \
		--disable-werror \
		--enable-kernel=2.6.27 \
		${cross_glibc_configure_args}

	make ${makejobs}
	make install_root=${wrksrc}/build_root/usr/${tgt} install

	touch ${wrksrc}/.glibc_build_done
}

_void_cross_build_musl() {
	[ -f ${wrksrc}/.musl_build_done ] && return 0

	local tgt=$1
	local ver=$2

	msg_normal "Patching musl for ${tgt}\n"

	cd ${wrksrc}/musl-${ver}
	if [ -d "${XBPS_SRCPKGDIR}/musl/patches" ]; then
		for f in ${XBPS_SRCPKGDIR}/musl/patches/*.patch; do
			_void_cross_apply_patch "$f"
		done
	fi
	cd ..

	msg_normal "Building musl for ${tgt}\n"

	mkdir -p musl_build
	cd musl_build

	CC="${tgt}-gcc" CXX="${tgt}-g++" CPP="${tgt}-cpp" LD="${tgt}-ld" \
	AR="${tgt}-ar" AS="${tgt}-as" NM="${tgt}-nm" \
	CFLAGS="-pipe -fPIC ${cross_musl_cflags}" \
	CPPFLAGS="${cross_musl_cflags}" LDFLAGS="${cross_musl_ldflags}" \
	../musl-${ver}/configure \
		--prefix=/usr \
		--host=${tgt} \
		${cross_musl_configure_args}

	make ${makejobs}
	make DESTDIR=${wrksrc}/build_root/usr/${tgt} install

	CFLAGS="-pipe -fPIC ${cross_musl_cflags}" \
	CPPFLAGS="${cross_musl_cflags}" LDFLAGS="${cross_musl_ldflags}" \
	${tgt}-gcc -pipe -fPIC ${cross_musl_cflags} ${cross_musl_ldflags} -fpie \
		-c ${XBPS_SRCPKGDIR}/musl/files/__stack_chk_fail_local.c \
		-o __stack_chk_fail_local.o
	${tgt}-ar r libssp_nonshared.a __stack_chk_fail_local.o
	cp libssp_nonshared.a ${wrksrc}/build_root/usr/${tgt}/usr/lib

	touch ${wrksrc}/.musl_build_done
}

_void_cross_build_libucontext() {
	[ -n "$cross_gcc_skip_go" ] && return 0
	[ -f ${wrksrc}/.libucontext_build_done ] && return 0

	local tgt=$1
	local ver=$2
	local arch incpath

	msg_normal "Building libucontext for ${tgt}\n"

	case "$tgt" in
		x86_64*) arch=x86_64 ;;
		i686*) arch=x86 ;;
		powerpc64*) arch=ppc64 ;;
		powerpc*) arch=ppc ;;
		mips*64*) arch=mips64 ;;
		mips*) arch=mips ;;
		aarch64*) arch=aarch64 ;;
		arm*) arch=arm ;;
		riscv64*) arch=riscv64 ;;
		s390x*) arch=s390x ;;
		*) msg_error "Unknown libucontext arch for ${tgt}\n" ;;
	esac

	cd ${wrksrc}/libucontext-${ver}
	# a terrible hack but seems to work for now
	# we build a static-only library to prevent linking to a runtime
	# since it's tiny it can be linked into libgo and we don't have
	# to keep it around (which would possibly conflict with crossdeps)
	incpath="${wrksrc}/build_root/usr/${tgt}/usr/include"
	CC="${tgt}-gcc" AS="${tgt}-as" AR="${tgt}-ar" \
	make ARCH=$arch libucontext.a \
		CFLAGS="${cross_musl_cflags} -g0 -nostdinc -isystem ${incpath}"

	cp libucontext.a ${wrksrc}/build_root/usr/${tgt}/usr/lib

	touch ${wrksrc}/.libucontext_build_done
}

_void_cross_build_gcc() {
	[ -f ${wrksrc}/.gcc_build_done ] && return 0

	local tgt=$1
	local ver=$2

	msg_normal "Building gcc for ${tgt}\n"

	# GIANT HACK: create an empty libatomic.a so gcc cross-compile
	# below works.
	ar r ${wrksrc}/build_root/usr/${tgt}/usr/lib/libatomic.a

	mkdir -p ${wrksrc}/gcc_build
	cd ${wrksrc}/gcc_build

	local langs="c,c++,fortran,objc,obj-c++,ada,lto"
	if [ -z "$cross_gcc_skip_go" ]; then
		langs+=",go"
	fi

	local extra_args
	if [ -f ${wrksrc}/.musl_version ]; then
		# otherwise glibc hosts get confused and use the gnu impl
		extra_args+=" --enable-clocale=generic"
		extra_args+=" --disable-symvers"
		extra_args+=" --disable-gnu-unique-object"
		extra_args+=" libat_cv_have_ifunc=no"
	else
		extra_args+=" --enable-clocale=gnu"
		extra_args+=" --enable-gnu-unique-object"
	fi

	# note on --disable-libquadmath:
	# on some platforms the library is actually necessary for the
	# fortran frontend to build, platforms where this is a problem
	# should explicitly force libquadmath to be on via cross_gcc_configure_args
	#
	../gcc-${ver}/configure \
		--prefix=/usr \
		--sbindir=/usr/bin \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--target=${tgt} \
		--with-sysroot=/usr/${tgt} \
		--with-build-sysroot=${wrksrc}/build_root/usr/${tgt} \
		--enable-languages=${langs} \
		--disable-nls \
		--disable-multilib \
		--disable-sjlj-exceptions \
		--disable-libquadmath \
		--disable-libmudflap \
		--disable-libitm \
		--disable-libvtv \
		--disable-libsanitizer \
		--disable-libstdcxx-pch \
		--disable-libssp \
		--enable-shared \
		--enable-threads=posix \
		--enable-__cxa_atexit \
		--enable-linker-build-id \
		--enable-libada \
		--enable-lto \
		--enable-default-pie \
		--enable-default-ssp \
		--with-gnu-ld \
		--with-gnu-as \
		--with-linker-hash-style=gnu \
		${extra_args} \
		${configure_args} \
		${cross_gcc_configure_args}

	make ${makejobs}

	touch ${wrksrc}/.gcc_build_done
}

_void_cross_test_ver() {
	local proj=$1
	local noerr=$2
	local ver cver
	for p in ${proj}-*; do
		cver=${p#${proj}-}
		if [ -z "$noerr" -a -n "$ver" ]; then
			msg_error "multiple versions of ${proj} found: ${ver}, ${cver}"
		fi
		ver=${cver}
	done
	if [ -d "${proj}-${ver}" ]; then
		echo ${ver} > ${wrksrc}/.${proj}_version
		return
	fi
	if [ -z "$noerr" ]; then
		msg_error "project ${proj} not available for build\n"
	fi
}

do_build() {
	# Verify toolchain versions
	cd ${wrksrc}

	local binutils_ver linux_ver gcc_ver libc_ver libucontext_ver
	local tgt=${sourcepkg/cross-}

	export CFLAGS="${CFLAGS/-D_FORTIFY_SOURCE=2/}"
	export CXXFLAGS="${CXXFLAGS/-D_FORTIFY_SOURCE=2/}"

	# Disable explicit -fno-PIE, gcc/binutils/libc will figure this out itself.
	export CFLAGS="${CFLAGS//-fno-PIE/}"
	export CXXFLAGS="${CXXFLAGS//-fno-PIE/}"
	export LDFLAGS="${LDFLAGS//-no-pie/}"

	_void_cross_test_ver binutils
	_void_cross_test_ver linux
	_void_cross_test_ver gcc

	binutils_ver=$(cat .binutils_version)
	linux_ver=$(cat .linux_version)
	gcc_ver=$(cat .gcc_version)

	_void_cross_test_ver musl noerr
	if [ ! -f .musl_version ]; then
		_void_cross_test_ver glibc
		libc_ver=$(cat .glibc_version)
	else
		libc_ver=$(cat .musl_version)
		if [ -z "$cross_gcc_skip_go" ]; then
			_void_cross_test_ver libucontext
			libucontext_ver=$(cat .libucontext_version)
		fi
	fi

	local sysroot="/usr/${tgt}"

	# Prepare environment
	cd ${wrksrc}

	# Core directories for the build root
	mkdir -p build_root/usr/{bin,lib,include,share}
	mkdir -p build_root/usr/${tgt}/usr/{bin,lib,include,share}

	# Host root uses host wordsize
	ln -sf usr/lib build_root/lib
	ln -sf usr/lib build_root/lib${XBPS_TARGET_WORDSIZE}
	ln -sf lib build_root/usr/lib${XBPS_TARGET_WORDSIZE}

	# Prepare target sysroot
	ln -sf usr/lib build_root/${sysroot}/lib
	ln -sf lib build_root/${sysroot}/usr/libexec

	_void_cross_build_binutils ${tgt} ${binutils_ver}

	# Prepare environment so we can use temporary prefix
	local oldpath="$PATH"
	local oldldlib="$LD_LIBRARY_PATH"

	export PATH="${wrksrc}/build_root/usr/bin:$PATH"
	export LD_LIBRARY_PATH="${wrksrc}/build_root/usr/lib:$PATH"

	_void_cross_build_bootstrap_gcc ${tgt} ${gcc_ver}
	_void_cross_build_kernel_headers ${tgt} ${linux_ver}

	local ws=$(cat ${wrksrc}/.gcc_wordsize)

	# Now that we know the target wordsize, prepare symlinks
	ln -sf usr/lib ${wrksrc}/build_root/${sysroot}/lib${ws}
	ln -sf lib ${wrksrc}/build_root/${sysroot}/usr/lib${ws}

	if [ -f ${wrksrc}/.musl_version ]; then
		_void_cross_build_musl ${tgt} ${libc_ver}
		_void_cross_build_libucontext ${tgt} ${libucontext_ver}
	else
		_void_cross_build_glibc_headers ${tgt} ${libc_ver}
		_void_cross_build_glibc ${tgt} ${libc_ver}
	fi

	_void_cross_build_gcc ${tgt} ${gcc_ver}

	# restore this stuff in case later hooks depend on it
	export PATH="$oldpath"
	export LD_LIBRARY_PATH="$oldldlib"
}

do_install() {
	# We need to be able to access binutils in the root
	local oldpath="$PATH"
	local oldldlib="$LD_LIBRARY_PATH"
	export PATH="${wrksrc}/build_root/usr/bin:$PATH"
	export LD_LIBRARY_PATH="${wrksrc}/build_root/usr/lib:$PATH"

	local tgt=${sourcepkg/cross-}
	local sysroot="/usr/${tgt}"
	local ws=$(cat ${wrksrc}/.gcc_wordsize)

	# Core directories for the sysroot
	#
	# libexec is created for sysroot but not for dest, since in sysroot
	# we configure glibc with separate libexec, elsewhere it's just lib
	# and we want to delete the libexec from glibc afterwards to save space
	mkdir -p ${DESTDIR}/${sysroot}/usr/{bin,lib,libexec,include,share}
	# Sysroot base symlinks
	ln -sf usr/bin ${DESTDIR}/${sysroot}/bin
	ln -sf usr/lib ${DESTDIR}/${sysroot}/lib
	ln -sf usr/lib ${DESTDIR}/${sysroot}/lib${ws}
	ln -sf lib ${DESTDIR}/${sysroot}/usr/lib${ws}
	ln -sf usr/include ${DESTDIR}/${sysroot}/include

	# Install Linux headers
	cd ${wrksrc}/linux-$(cat ${wrksrc}/.linux_version)
	cp -a usr/include ${DESTDIR}/${sysroot}/usr

	# Install binutils
	cd ${wrksrc}/binutils_build
	make install DESTDIR=${DESTDIR}

	# Install final gcc
	cd ${wrksrc}/gcc_build
	make install DESTDIR=${DESTDIR}

	# Move libcc1.so* to the sysroot
	mv ${DESTDIR}/usr/lib/libcc1.so* ${DESTDIR}/${sysroot}/usr/lib

	local gcc_ver=$(cat ${wrksrc}/.gcc_version)
	local gcc_patch=${gcc_ver/_*}
	local gcc_minor=${gcc_patch%.*}
	local gcc_major=${gcc_minor%.*}

	if [ -f ${wrksrc}/.musl_version ]; then
		# Install musl
		cd ${wrksrc}/musl_build
		make DESTDIR=${DESTDIR}/${sysroot} install

		# Remove useless headers
		rm -rf ${DESTDIR}/usr/lib/gcc/${tgt}/*/include-fixed

		# Make ld-musl.so symlinks relative
		for f in ${DESTDIR}/${sysroot}/usr/lib/ld-musl-*.so.*; do
			ln -sf libc.so ${f}
		done

		cp libssp_nonshared.a ${DESTDIR}/${sysroot}/usr/lib/
	else
		# Install glibc
		cd ${wrksrc}/glibc_build
		make install_root=${DESTDIR}/${sysroot} install install-headers

		# Remove bad header
		rm -f ${DESTDIR}/usr/lib/gcc/${tgt}/${gcc_patch}/include-fixed/bits/statx.h
	fi

	# minor-versioned symlinks
	mv ${DESTDIR}/usr/lib/gcc/${tgt}/${gcc_patch} \
		${DESTDIR}/usr/lib/gcc/${tgt}/${gcc_minor}
	ln -sfr ${DESTDIR}/usr/lib/gcc/${tgt}/${gcc_minor} \
		${DESTDIR}/usr/lib/gcc/${tgt}/${gcc_patch}

	# ditto for c++ headers
	mv ${DESTDIR}/${sysroot}/usr/include/c++/${gcc_patch} \
		${DESTDIR}/${sysroot}/usr/include/c++/${gcc_minor}
	ln -sfr ${DESTDIR}/${sysroot}/usr/include/c++/${gcc_minor} \
		${DESTDIR}/${sysroot}/usr/include/c++/${gcc_patch}

	# Symlinks for gnarl and gnat shared libraries
	local adalib=usr/lib/gcc/${tgt}/${gcc_patch}/adalib
	mv ${DESTDIR}/${adalib}/libgnarl-${gcc_major}.so \
		${DESTDIR}/${sysroot}/usr/lib
	mv ${DESTDIR}/${adalib}/libgnat-${gcc_major}.so \
		${DESTDIR}/${sysroot}/usr/lib
	ln -sf libgnarl-${gcc_major}.so ${DESTDIR}/${sysroot}/usr/lib/libgnarl.so
	ln -sf libgnat-${gcc_major}.so ${DESTDIR}/${sysroot}/usr/lib/libgnat.so
	rm -vf ${DESTDIR}/${adalib}/libgna{rl,t}.so

	# Remove libgomp library because it conflicts with libgomp and
	# libgomp-devel packages
	rm -f ${DESTDIR}/${sysroot}/usr/lib/libgomp*

	# Remove libdep linker plugin because it conflicts with system binutils
	rm -f ${DESTDIR}/usr/lib/bfd-plugins/libdep*

	# Remove leftover symlinks
	rm -f ${DESTDIR}/usr/lib${XBPS_TARGET_WORDSIZE}
	rm -f ${DESTDIR}/lib*
	rm -f ${DESTDIR}/*bin
	# Remove unnecessary stuff
	rm -rf ${DESTDIR}/${sysroot}/{sbin,etc,var,libexec}
	rm -rf ${DESTDIR}/${sysroot}/usr/{sbin,share,libexec}
	rm -rf ${DESTDIR}/usr/share
	rm -f ${DESTDIR}/usr/lib*/libiberty.a

	export PATH="$oldpath"
	export LD_LIBRARY_PATH="$oldldlib"
}
