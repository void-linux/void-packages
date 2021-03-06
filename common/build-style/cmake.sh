#
# This helper is for templates using cmake.
#
do_configure() {
	local cmake_args=
	[ ! -d ${cmake_builddir:=build} ] && mkdir -p ${cmake_builddir}
	cd ${cmake_builddir}

	if [ -z "$CHROOT_READY" ]; then
		cat >bootstrap.cmake <<_EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)

SET(CMAKE_C_COMPILER   ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})

SET(CMAKE_FIND_ROOT_PATH  "${XBPS_MASTERDIR}/usr;${XBPS_MASTERDIR}")

SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
_EOF
		configure_args+=" -DCMAKE_TOOLCHAIN_FILE=bootstrap.cmake"
	elif [ "$CROSS_BUILD" ]; then
		case "$XBPS_TARGET_MACHINE" in
			x86_64*) _CMAKE_SYSTEM_PROCESSOR=x86_64 ;;
			i686*) _CMAKE_SYSTEM_PROCESSOR=x86 ;;
			aarch64*) _CMAKE_SYSTEM_PROCESSOR=aarch64 ;;
			arm*) _CMAKE_SYSTEM_PROCESSOR=arm ;;
			mips*) _CMAKE_SYSTEM_PROCESSOR=mips ;;
			ppc64le*) _CMAKE_SYSTEM_PROCESSOR=ppc64le ;;
			ppc64*) _CMAKE_SYSTEM_PROCESSOR=ppc64 ;;
			ppcle*) _CMAKE_SYSTEM_PROCESSOR=ppcle ;;
			ppc*) _CMAKE_SYSTEM_PROCESSOR=ppc ;;
			*) _CMAKE_SYSTEM_PROCESSOR=generic ;;
		esac
		cat > cross_${XBPS_CROSS_TRIPLET}.cmake <<_EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)

SET(CMAKE_C_COMPILER   ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_CROSSCOMPILING TRUE)

SET(CMAKE_SYSTEM_PROCESSOR ${_CMAKE_SYSTEM_PROCESSOR})

SET(CMAKE_FIND_ROOT_PATH  "${XBPS_CROSS_BASE}/usr;${XBPS_CROSS_BASE}")

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
_EOF
		cmake_args+=" -DCMAKE_TOOLCHAIN_FILE=cross_${XBPS_CROSS_TRIPLET}.cmake"
	fi
	cmake_args+=" -DCMAKE_INSTALL_PREFIX=/usr"
	cmake_args+=" -DCMAKE_BUILD_TYPE=Release"
	cmake_args+=" -DCMAKE_INSTALL_LIBDIR=lib${XBPS_TARGET_WORDSIZE}"

	if [[ $build_helper = *"qemu"* ]]; then
		echo "SET(CMAKE_CROSSCOMPILING_EMULATOR /usr/bin/qemu-${XBPS_TARGET_QEMU_MACHINE}-static)" \
			>> cross_${XBPS_CROSS_TRIPLET}.cmake
	fi

	cmake_args+=" -DCMAKE_INSTALL_SBINDIR=bin"

	export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"
	# Override flags: https://gitlab.kitware.com/cmake/cmake/issues/19590
	CFLAGS="${CFLAGS/ -pipe / }" CXXFLAGS="${CXXFLAGS/ -pipe / }" \
		cmake ${cmake_args} ${configure_args} ${wrksrc}/${build_wrksrc}

	# Replace -isystem with -I
	if [ "$CMAKE_GENERATOR" = "Unix Makefiles" ]; then
		find . -name flags.make -exec sed -i -e 's/-isystem/-I/g' "{}" +
	elif [ "$CMAKE_GENERATOR" = Ninja ]; then
		sed -i -e 's/-isystem/-I/g' build.ninja
	fi
}

do_build() {
	: ${make_cmd:=ninja}

	cd ${cmake_builddir:=build}
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_check() {
	: ${make_cmd:=ninja}

	cd ${cmake_builddir:=build}

	if [ -z "$make_check_target" ]; then
		case $make_cmd in
			make)
				if make -q test 2>/dev/null; then
					:
				else
					if [ $? -eq 2 ]; then
						msg_warn 'No target to "make test".\n'
						return 0
					fi
				fi
				;;
			ninja)
				if ! ninja -t query test >/dev/null 2>&1; then
					msg_warn 'No target to "ninja test".\n'
					return 0
				fi
				;;
			*)
				msg_warn "Can't run tests with '$make_cmd', define do_check.\n"
				;;
		esac
	fi

	: ${make_check_target:=test}

	CTEST_OUTPUT_ON_FAILURE=TRUE ${make_cmd} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=ninja}
	: ${make_install_target:=install}

	cd ${cmake_builddir:=build}
	DESTDIR=${DESTDIR} ${make_cmd} ${make_install_args} ${make_install_target}
}
