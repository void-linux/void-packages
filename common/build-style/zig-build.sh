do_build() {
	local zig_abi
	local zig_target
	local zig_cpu

	case $XBPS_TARGET_LIBC in
		glibc) zig_abi="gnu";;
		musl) zig_abi="musl";;
		*) broken="Unknown target libc";;
	esac

	case $XBPS_TARGET_MACHINE in
		aarch64*|i686*|x86_64*)
			zig_target="${XBPS_TARGET_MACHINE%-musl}-linux-${zig_abi}" zig_cpu="baseline";;
		armv6l*) zig_target="arm-linux-${zig_abi}" zig_cpu="generic+v6";;
		armv7l*) zig_target="arm-linux-${zig_abi}" zig_cpu="generic+v7a";;
		ppc64le*) zig_target="powerpc64le-linux-${zig_abi}" zig_cpu="baseline";;
		ppc64*) zig_target="powerpc64-linux-${zig_abi}" zig_cpu="baseline";;
		ppcle*) zig_target="powerpcle-linux-${zig_abi}" zig_cpu="baseline";;
		ppc*) zig_target="powerpc-linux-${zig_abi}" zig_cpu="baseline";;
		*) broken="TODO: support more target machines for the zig build style";;
	esac

	# Inform zig of the required libc include paths.
	cat > xbps_zig_libc.txt <<-EOF
		include_dir=${XBPS_CROSS_BASE}/usr/include
		sys_include_dir=${XBPS_CROSS_BASE}/usr/include
		crt_dir=${XBPS_CROSS_BASE}/usr/lib
		msvc_lib_dir=
		kernel32_lib_dir=
		gcc_dir=
	EOF

	# The Zig build system only has a single install step, there is no
	# way to build artifacts for a given prefix and then install those artifacts
	# to that prefix at some later time. Therefore, we build and install to the zig-out
	# directory and later copy the artifacts to the destdir in do_install().
	# We use zig-out to avoid path conflicts as it is the default install
	# prefix used by the zig build system.
	DESTDIR="zig-out" zig build \
		--sysroot "${XBPS_CROSS_BASE}" \
		--libc xbps_zig_libc.txt \
		-Dtarget=$zig_target -Dcpu=$zig_cpu \
		-Drelease-safe --prefix /usr install
}

do_install() {
	cp -r zig-out/* "${DESTDIR}"
}
