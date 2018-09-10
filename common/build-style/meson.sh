#
# This helper is for templates using meson.
#
do_configure() {
	: ${meson_cmd:=meson}
	: ${meson_builddir:=build}
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
ar = '${AR}'
ld = '${LD}'
strip = '${STRIP}'
readelf = '${READELF}'
pkgconfig = 'pkg-config'

[properties]
needs_exe_wrapper = true
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
		configure_args+=" --cross-file=${meson_crossfile}"

		# Meson tries to compile natively with CC, CXX, so when cross
		# compiling, we need to set those to the host versions.
		export CC=${CC_host} CXX=${CXX_host}

		# Meson tries to use CFLAGS and CPPFLAGS when compiling under
		# native: true, so we use XBPS_CFLAGS and XBPS_CPPFLAGS which
		# are set to (C|CXX)FLAGS_host
		export CFLAGS=${CFLAGS_host} CXXFLAGS=${CXXFLAGS_host}

		# Meson tries to use our wrapped cross-only pkg-config to find
		# libraries even when 'native: true' (build against the host platform)
		# is set, so set the PKG_CONFIG variable to tell Meson which pkg-config
		# it should use when searching for stuff in the build machine
		export PKG_CONFIG="/usr/bin/pkg-config"

		unset _MESON_CPU_FAMILY _MESON_TARGET_CPU _MESON_TARGET_ENDIAN
	fi

	# Enable meson Unity builds
	# https://mesonbuild.com/Unity-builds.html
	configure_args+=" --unity on"

	${meson_cmd} --prefix=/usr --buildtype=plain ${configure_args} . ${meson_builddir}
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

	${make_cmd} -C ${meson_builddir} ${makejobs} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=ninja}
	: ${make_install_target:=install}
	: ${meson_builddir:=build}

	DESTDIR=${DESTDIR} ${make_cmd} -C ${meson_builddir} ${make_install_args} ${make_install_target}
}
