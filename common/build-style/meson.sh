#
# This helper is for templates using meson.
#

do_configure() {
	: ${meson_cmd:=meson}
	: ${meson_builddir:=build}
	: ${meson_nativefile:="${XBPS_WRAPPERDIR}/meson/xbps_meson.native"}
	: ${meson_crossfile:="${XBPS_WRAPPERDIR}/meson/xbps_meson.cross"}

	if [ "$CROSS_BUILD" ]; then
		configure_args+=" --cross-file=${meson_crossfile}"
	else
		configure_args+=" --native-file=${meson_nativefile}"
	fi

	# binutils ar needs a plugin when LTO is used on static libraries, so we
	# have to use the gcc-ar wrapper that calls the correct plugin.
	# As seen in https://github.com/mesonbuild/meson/issues/1646 (and its
	# solution, https://github.com/mesonbuild/meson/pull/1649), meson fixed
	# issues with static libraries + LTO by defaulting to gcc-ar themselves.
	# We also force gcc-ar usage in the crossfile above.
	export AR="gcc-ar"

	${meson_cmd} setup ${configure_args} . ${meson_builddir}
}

do_build() {
	: ${make_cmd:=ninja}
	: ${make_build_target:=all}
	: ${meson_builddir:=build}

	case "${make_cmd}" in
	ninja|samu) : ${make_verbose:=-v} ;;
	esac

	${make_cmd} -C ${meson_builddir} ${XBPS_VERBOSE+${make_verbose}} ${makejobs} ${make_build_args} ${make_build_target}
}

do_check() {
	: ${make_cmd:=meson}
	: ${make_check_target:=test}
	: ${meson_builddir:=build}

	case "${make_cmd}" in
	ninja|samu) : ${make_verbose:=-v} ;;
	esac

	${make_check_pre} ${make_cmd} ${make_check_target} ${XBPS_VERBOSE+${make_verbose}} -C ${meson_builddir} ${makejobs} ${make_check_args}
}

do_install() {
	: ${make_cmd:=ninja}
	: ${make_install_target:=install}
	: ${meson_builddir:=build}

	case "${make_cmd}" in
	ninja|samu) : ${make_verbose:=-v} ;;
	esac

	DESTDIR=${DESTDIR} ${make_cmd} ${XBPS_VERBOSE+${make_verbose}} -C ${meson_builddir} ${make_install_args} ${make_install_target}
}
