# This build helper writes a Meson cross-file, allowing other build styles
# to properly drive cross-builds in Meson when appropriate

# Action is only taken for cross builds
[ -z "$CROSS_BUILD" ] && return 0

# The cross file should only be written once, unless forced
[ -e "${XBPS_WRAPPERDIR}/meson/xbps_meson.cross" ] && [ -z "$XBPS_BUILD_FORCEMODE" ] && return 0

mkdir -p "${XBPS_WRAPPERDIR}/meson"

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

# Tell meson to run binaries with qemu if desired
_MESON_EXE_WRAPPER=""
if [[ "${build_helper}" = *qemu* ]]; then
	_MESON_EXE_WRAPPER="exe_wrapper = '/usr/bin/qemu-${XBPS_TARGET_QEMU_MACHINE}'"
fi

# Record cross-compiling information in cross file.
#
# CFLAGS, CXXFLAGS and LDFLAGS are not yet available and
# will be taken from the environment at configure time.
cat > "${XBPS_WRAPPERDIR}/meson/xbps_meson.cross" <<-EOF
	[binaries]
	${_MESON_EXE_WRAPPER:-# exe_wrapper is not set}
	c = '${CC}'
	cpp = '${CXX}'
	ar = '${XBPS_CROSS_TRIPLET}-gcc-ar'
	nm = '${NM}'
	strip = '${STRIP}'
	readelf = '${READELF}'
	objcopy = '${OBJCOPY}'
	pkg-config = '${PKG_CONFIG}'
	rust = ['rustc', '--target', '${RUST_TARGET}' ,'--sysroot', '${XBPS_CROSS_BASE}/usr']
	g-ir-scanner = '${XBPS_CROSS_BASE}/usr/bin/g-ir-scanner'
	g-ir-compiler = '${XBPS_CROSS_BASE}/usr/bin/g-ir-compiler'
	g-ir-generate = '${XBPS_CROSS_BASE}/usr/bin/g-ir-generate'
	llvm-config = 'llvm-config-qemu'
	cups-config = '${XBPS_CROSS_BASE}/usr/bin/cups-config'

	[properties]
	needs_exe_wrapper = true
	bindgen_clang_arguments = ['-target', '${XBPS_CROSS_TRIPLET}']

	[host_machine]
	system = 'linux'
	cpu_family = '${_MESON_CPU_FAMILY}'
	cpu = '${_MESON_TARGET_CPU}'
	endian = '${_MESON_TARGET_ENDIAN}'
	EOF

unset _MESON_CPU_FAMILY _MESON_TARGET_CPU _MESON_TARGET_ENDIAN _MESON_EXE_WRAPPER
