#
# This helper is for templates using Qt4/Qt5 qmake.
#
do_configure() {
	: ${configure_script:=qmake}

	if [ -n "$build_pie" ]; then
		${configure_script} ${configure_args} \
			QMAKE_LFLAGS_SHLIB+=" -Wl,-z,now" \
			QMAKE_LFLAGS_PLUGIN+=" -Wl,-z,now"
	else
		${configure_script} ${configure_args}
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
		INSTALL_ROOT=${DESTDIR}/usr ${make_install_args} ${make_install_target}
}
