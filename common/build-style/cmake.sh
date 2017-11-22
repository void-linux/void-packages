#
# This helper is for templates using cmake.
#
do_configure() {
	local cmake_args=
	[ ! -d ${cmake_builddir:=build} ] && mkdir -p ${cmake_builddir}
	cd ${cmake_builddir}

	if [ "$CROSS_BUILD" ]; then
		cat > cross_${XBPS_CROSS_TRIPLET}.cmake <<_EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)

SET(CMAKE_C_COMPILER   ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_CROSSCOMPILING TRUE)

SET(CMAKE_FIND_ROOT_PATH  ${XBPS_CROSS_BASE})

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
_EOF
		cmake_args+=" -DCMAKE_TOOLCHAIN_FILE=cross_${XBPS_CROSS_TRIPLET}.cmake"
	fi
	cmake_args+=" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release"

	if [ "$XBPS_TARGET_MACHINE" = "i686" ]; then
		cmake_args+=" -DCMAKE_INSTALL_LIBDIR=lib32"
	else
		cmake_args+=" -DCMAKE_INSTALL_LIBDIR=lib"
	fi

	cmake_args+=" -DCMAKE_INSTALL_SBINDIR=bin"

	cmake ${cmake_args} ${configure_args} $(echo ${cmake_builddir}|sed \
		-e 's|[^/]$|/|' -e 's|[^/]*||g' -e 's|/|../|g')

	# Replace -isystem with -I for Qt4 and Qt5 packages
	find -name flags.make -exec sed -i "{}" -e"s;-isystem;-I;g" \;
}

do_build() {
	: ${make_cmd:=make}

	cd ${cmake_builddir:=build}
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_check() {
	if [ -z "$make_cmd" ] && [ -z "$make_check_target" ]; then
		if make -q test 2>/dev/null; then
			:
		else
			if [ $? -eq 2 ]; then
				msg_warn 'No target to "make test".\n'
				return 0
			fi
		fi
	fi

	: ${make_cmd:=make}
	: ${make_check_target:=test}

	${make_cmd} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	cd ${cmake_builddir:=build}
	${make_cmd} DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
	cd ${wrksrc}
}
