#
# This helper is for templates using meson.
#

do_configure() {
	: ${meson_cmd:=meson}
	: ${meson_builddir:=build}
	: ${meson_crossfile:="${XBPS_WRAPPERDIR}/meson/xbps_meson.cross"}

	if [ "$CROSS_BUILD" ]; then
		configure_args+=" --cross-file=${meson_crossfile}"
	fi

	# binutils ar needs a plugin when LTO is used on static libraries, so we
	# have to use the gcc-ar wrapper that calls the correct plugin.
	# As seen in https://github.com/mesonbuild/meson/issues/1646 (and its
	# solution, https://github.com/mesonbuild/meson/pull/1649), meson fixed
	# issues with static libraries + LTO by defaulting to gcc-ar themselves.
	# We also force gcc-ar usage in the crossfile above.
	export AR="gcc-ar"

	# unbuffered output for continuous logging
	${meson_cmd} setup \
		--prefix=/usr \
		--libdir=/usr/lib${XBPS_TARGET_WORDSIZE} \
		--libexecdir=/usr/libexec \
		--bindir=/usr/bin \
		--sbindir=/usr/bin \
		--includedir=/usr/include \
		--datadir=/usr/share \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--localedir=/usr/share/locale \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--sharedstatedir=/var/lib \
		--buildtype=plain \
		--auto-features=auto \
		--wrap-mode=nodownload \
		-Db_lto=true -Db_ndebug=true \
		-Db_staticpic=true \
		-Dpkgconfig.relocatable=false \
		${configure_args} . ${meson_builddir}
}

do_build() {
	: ${make_cmd:=ninja}
	: ${make_build_target:=all}
	: ${meson_builddir:=build}

	${make_cmd} -C ${meson_builddir} ${makejobs} ${make_build_args} ${make_build_target}
}

do_check() {
	: ${make_cmd:=meson}
	: ${make_check_target:=test}
	: ${meson_builddir:=build}

	${make_check_pre} ${make_cmd} ${make_check_target} -C ${meson_builddir} ${makejobs} ${make_check_args}
}

do_install() {
	: ${make_cmd:=ninja}
	: ${make_install_target:=install}
	: ${meson_builddir:=build}

	DESTDIR=${DESTDIR} ${make_cmd} -C ${meson_builddir} ${make_install_args} ${make_install_target}
}
