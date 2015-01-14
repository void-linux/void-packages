#
# This helper is for templates using cmake.
#
do_configure() {
	[ ! -d build ] && mkdir build
	cd build

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

	configure_args+=" -DCMAKE_INSTALL_SBINDIR=sbin"

	cmake ${configure_args} ..
}

do_build() {
	: ${make_cmd:=make}

	cd build
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	make_install_args+=" DESTDIR=${DESTDIR}"

	cd build
	${make_cmd} ${make_install_args} ${make_install_target}
}
