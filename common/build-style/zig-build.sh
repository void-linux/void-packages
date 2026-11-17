do_build() {
	local zig=zig zig_target zig_cpu zig_search_prefix dep

	# Use a versioned zig binary if the template pins a release so the result
	# does not depend on the zig alternatives group.
	for dep in ${hostmakedepends}; do
		case "${dep}" in
		zig[0-9]*) zig="${dep%%[<>=]*}" ;;
		esac
	done

	# Since zig 0.14, absolute -L paths (from --search-prefix and pkg-config)
	# are only looked up inside --sysroot, so the sysroot must not be empty
	# and the search prefix must be given relative to it. The search prefix is
	# also checked on the host filesystem, so for cross builds use / to only
	# get -L /lib (${XBPS_CROSS_BASE}/lib) and no -I with host headers.
	# TODO: This duplication between build-profiles and cross-profiles
	# is totally unnecessary. It would be nice if there was some way to
	# avoid it.
	if [ "$CROSS_BUILD" ]; then
		zig_target="${XBPS_CROSS_ZIG_TARGET}"
		zig_cpu="${XBPS_CROSS_ZIG_CPU}"
		zig_search_prefix=/
	else
		zig_target="${XBPS_ZIG_TARGET}"
		zig_cpu="${XBPS_ZIG_CPU}"
		zig_search_prefix=/usr
	fi

	# Inform zig of the required libc include paths.
	#
	# zig 0.17 requires gcc_dir to point to the directory with crtbegin*.o on Linux
	# and darwin_sdk_dir must be present. Older versions ignore unknown keys.
	cat > xbps_zig_libc.txt <<-EOF
		include_dir=${XBPS_CROSS_BASE}/usr/include
		sys_include_dir=${XBPS_CROSS_BASE}/usr/include
		crt_dir=${XBPS_CROSS_BASE}/usr/lib
		msvc_lib_dir=
		kernel32_lib_dir=
		gcc_dir=$(dirname "$(${CC:-cc} -print-file-name=crtbeginS.o)")
		darwin_sdk_dir=
	EOF

	# The Zig build system only has a single install step, there is no
	# way to build artifacts for a given prefix and then install those artifacts
	# to that prefix at some later time. Therefore, we build and install to the zig-out
	# directory and later copy the artifacts to the destdir in do_install().
	# We use zig-out to avoid path conflicts as it is the default install
	# prefix used by the zig build system.
	#
	# zig 0.17 dropped the --global-cache-dir option, the environment variable works
	# with all versions.
	DESTDIR="zig-out" ZIG_GLOBAL_CACHE_DIR=/host/zig "${zig}" build \
		${makejobs} \
		--sysroot "${XBPS_CROSS_BASE:-/}" \
		--search-prefix "${zig_search_prefix}" \
		--prefix /usr \
		--libc xbps_zig_libc.txt \
		--release=safe \
		--verbose \
		-Dtarget="${zig_target}" -Dcpu="${zig_cpu}" \
		install \
		${configure_args}
}

do_install() {
	cp -r zig-out/* "${DESTDIR}"
}
