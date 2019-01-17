#
# This helper is for templates using cmake.
#
do_configure() {
	local cmake_args=
	[ ! -d ${cmake_builddir:=build} ] && mkdir -p ${cmake_builddir}
	cd ${cmake_builddir}

	if [ "$CROSS_BUILD" ]; then
		case "$XBPS_TARGET_MACHINE" in
			x86_64*) _CMAKE_SYSTEM_PROCESSOR=x86_64 ;;
			i686*) _CMAKE_SYSTEM_PROCESSOR=x86 ;;
			aarch64*) _CMAKE_SYSTEM_PROCESSOR=aarch64 ;;
			arm*) _CMAKE_SYSTEM_PROCESSOR=arm ;;
			mips*) _CMAKE_SYSTEM_PROCESSOR=mips ;;
			ppc64le*) _CMAKE_SYSTEM_PROCESSOR=ppc64le ;;
			ppc64*) _CMAKE_SYSTEM_PROCESSOR=ppc64 ;;
			*) _CMAKE_SYSTEM_PROCESSOR=generic ;;
		esac
		if [ -x "${XBPS_CROSS_BASE}/usr/bin/wx-config-gtk3" ]; then
			wx_config=wx-config-gtk3
		fi
		cat > cross_${XBPS_CROSS_TRIPLET}.cmake <<_EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1)

SET(CMAKE_C_COMPILER   ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_CROSSCOMPILING TRUE)

SET(CMAKE_SYSTEM_PROCESSOR ${_CMAKE_SYSTEM_PROCESSOR})

SET(CMAKE_FIND_ROOT_PATH  ${XBPS_CROSS_BASE})

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

SET(wxWidgets_CONFIG_EXECUTABLE ${XBPS_WRAPPERDIR}/${wx_config:=wx-config})
_EOF
		cmake_args+=" -DCMAKE_TOOLCHAIN_FILE=cross_${XBPS_CROSS_TRIPLET}.cmake"
	fi
	cmake_args+=" -DCMAKE_INSTALL_PREFIX=/usr"

	if [ -n "$XBPS_DEBUG_PKGS" ]; then
		cmake_args+=" -DCMAKE_BUILD_TYPE=RelWithDebInfo"
	else
		cmake_args+=" -DCMAKE_BUILD_TYPE=Release"
	fi

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
	cd ${cmake_builddir:=build}

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
}
