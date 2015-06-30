#
# This helper is for templates using cmake.
#
do_configure() {
	[ ! -d ${cmake_builddir:=build} ] && mkdir -p ${cmake_builddir}
	cd ${cmake_builddir}

	if [ "$CROSS_BUILD" ]; then
		cat > cross_${XBPS_CROSS_TRIPLET}.cmake <<_EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)

SET(CMAKE_C_COMPILER   ${XBPS_CROSS_TRIPLET}-gcc)
SET(CMAKE_CXX_COMPILER ${XBPS_CROSS_TRIPLET}-g++)
SET(CMAKE_CROSSCOMPILING TRUE)

SET(CMAKE_FIND_ROOT_PATH  ${XBPS_CROSS_BASE})

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
_EOF
		configure_args+=" -DCMAKE_TOOLCHAIN_FILE=cross_${XBPS_CROSS_TRIPLET}.cmake"
	fi
	configure_args+=" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release"

	if [ "$XBPS_TARGET_MACHINE" = "i686" ]; then
		configure_args+=" -DCMAKE_INSTALL_LIBDIR=lib32"
	else
		configure_args+=" -DCMAKE_INSTALL_LIBDIR=lib"
	fi

	configure_args+=" -DCMAKE_INSTALL_SBINDIR=bin"

	cmake ${configure_args} $(echo ${cmake_builddir}|sed \
		-e 's|[^/]$|/|' -e 's|[^/]*||g' -e 's|/|../|g')
}

do_build() {
	: ${make_cmd:=make}

	cd ${cmake_builddir:=build}
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	cd ${cmake_builddir:=build}
	${make_cmd} DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
