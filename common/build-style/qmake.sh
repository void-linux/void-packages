#
# This helper is for templates using Qt4/Qt5 qmake.
#
do_configure() {
	if [ -n "$build_pie" ]; then
		qmake ${configure_args} \
			QMAKE_LFLAGS_SHLIB+=" -Wl,-z,now" \
			QMAKE_LFLAGS_PLUGIN+=" -Wl,-z,now"
	else
		qmake ${configure_args}
	fi
}

do_build() {
	: ${make_cmd:=make}

	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} STRIP=true PREFIX=/usr DESTDIR=${DESTDIR} \
		INSTALL_ROOT=${DESTDIR} ${make_install_args} ${make_install_target}
}
