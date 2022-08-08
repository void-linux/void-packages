#
# This helper is for templates using meson.
#
do_patch() {
	: ${meson_crossfile:=xbps_meson.cross}

	if [ "$CROSS_BUILD" ]; then
		_MESON_TARGET_ENDIAN=little
		# drop the -musl suffix to the target cpu, meson doesn't recognize it
		_MESON_TARGET_CPU=${XBPS_TARGET_MACHINE/-musl/}
		case "$XBPS_TARGET_MACHINE" in
			mips|mips-musl|mipshf-musl)
				_MESON_TARGET_ENDIAN=big
				_MESON_CPU_FAMILY=mips
				;;
			armv*)
				_MESON_CPU_FAMILY=arm
				;;
			i686*)
				_MESON_CPU_FAMILY=x86
				;;
			ppc64le*)
				_MESON_CPU_FAMILY=ppc64
				;;
			ppc64*)
				_MESON_TARGET_ENDIAN=big
				_MESON_CPU_FAMILY=ppc64
				;;
			ppcle*)
				_MESON_CPU_FAMILY=ppc
				;;
			ppc*)
				_MESON_TARGET_ENDIAN=big
				_MESON_CPU_FAMILY=ppc
				;;
			*)
				# if we reached here that means that the cpu and cpu_family
				# are the same like 'x86_64' and 'aarch64'
				_MESON_CPU_FAMILY=${_MESON_TARGET_CPU}
				;;
		esac

		# Record cross-compiling information in cross file.
		# CFLAGS and LDFLAGS must be set as c_args and c_link_args.
		cat > ${meson_crossfile} <<EOF
[binaries]
c = '${CC}'
cpp = '${CXX}'
ar = '${XBPS_CROSS_TRIPLET}-gcc-ar'
nm = '${NM}'
ld = '${LD}'
strip = '${STRIP}'
readelf = '${READELF}'
objcopy = '${OBJCOPY}'
pkgconfig = '${PKG_CONFIG}'
rust = ['rustc', '--target', '${RUST_TARGET}' ,'--sysroot', '${XBPS_CROSS_BASE}/usr']
g-ir-scanner = '${XBPS_CROSS_BASE}/usr/bin/g-ir-scanner'
g-ir-compiler = '${XBPS_CROSS_BASE}/usr/bin/g-ir-compiler'
g-ir-generate = '${XBPS_CROSS_BASE}/usr/bin/g-ir-generate'
llvm-config = '/usr/bin/llvm-config'
cups-config = '${XBPS_CROSS_BASE}/usr/bin/cups-config'

[properties]
needs_exe_wrapper = true

[built-in options]
c_args = ['$(echo ${CFLAGS} | sed -r "s/\s+/','/g")']
c_link_args = ['$(echo ${LDFLAGS} | sed -r "s/\s+/','/g")']

cpp_args = ['$(echo ${CXXFLAGS} | sed -r "s/\s+/','/g")']
cpp_link_args = ['$(echo ${LDFLAGS} | sed -r "s/\s+/','/g")']

[host_machine]
system = 'linux'
cpu_family = '${_MESON_CPU_FAMILY}'
cpu = '${_MESON_TARGET_CPU}'
endian = '${_MESON_TARGET_ENDIAN}'
EOF
		if [[ $build_helper = *"qemu"* ]]; then
			sed -e "/\[binaries\]/ a exe_wrapper = '/usr/bin/qemu-${XBPS_TARGET_QEMU_MACHINE}-static'" \
				-i ${meson_crossfile}
		fi

		unset _MESON_CPU_FAMILY _MESON_TARGET_CPU _MESON_TARGET_ENDIAN
	fi
}

do_configure() {
	: ${meson_cmd:=meson}
	: ${meson_builddir:=build}
	: ${meson_crossfile:=xbps_meson.cross}

	if [ "$CROSS_BUILD" ]; then
		configure_args+=" --cross-file=${meson_crossfile}"
	fi

	# binutils ar needs a plugin when LTO is used on static libraries, so we
	# have to use the gcc-ar wrapper that calls the correct plugin.
	# As seen in https://github.com/mesonbuild/meson/issues/1646 (and its
	# solution, https://github.com/mesonbuild/meson/pull/1649), meson fixed
	# issues with static libraries + LTO by defaulting to gcc-ar themselves.
	# We also force gcc-ar usage in the crossfile above.
	export AR="gcc-ar"

	# unbuffered output for continuous logging
	PYTHONUNBUFFERED=1 ${meson_cmd} \
		--prefix=/usr \
		--libdir=/usr/lib${XBPS_TARGET_WORDSIZE} \
		--libexecdir=/usr/libexec \
		--bindir=/usr/bin \
		--sbindir=/usr/bin \
		--includedir=/usr/include \
		--datadir=/usr/share \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--localedir=/usr/share/locale \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--sharedstatedir=/var/lib \
		--buildtype=plain \
		--auto-features=auto \
		--wrap-mode=nodownload \
		-Db_lto=true -Db_ndebug=true \
		-Db_staticpic=true \
		${configure_args} . ${meson_builddir}
}

do_build() {
	: ${make_cmd:=ninja}
	: ${make_build_target:=all}
	: ${meson_builddir:=build}

	${make_cmd} -C ${meson_builddir} ${makejobs} ${make_build_args} ${make_build_target}
}

do_check() {
	: ${make_cmd:=ninja}
	: ${make_check_target:=test}
	: ${meson_builddir:=build}

	${make_check_pre} ${make_cmd} -C ${meson_builddir} ${makejobs} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=ninja}
	: ${make_install_target:=install}
	: ${meson_builddir:=build}

	DESTDIR=${DESTDIR} ${make_cmd} -C ${meson_builddir} ${make_install_args} ${make_install_target}
}
