#
# This helper is for templates using GNU configure scripts.
#
do_configure() {
	: ${meson_cmd:=meson}
	: ${meson_builddir:=build}

	${meson_cmd} --prefix=/usr --buildtype=plain ${configure_args} . ${meson_builddir}
}

do_build() {
	: ${make_cmd:=ninja}
	: ${make_build_target:=all}
	: ${meson_builddir:=build}

	${make_cmd} -C ${meson_builddir} ${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=ninja}
	: ${make_install_target:=install}
	: ${meson_builddir:=build}

	DESTDIR=${DESTDIR} ${make_cmd} -C ${meson_builddir} ${make_install_args} ${make_install_target}
}
