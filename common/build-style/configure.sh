#
# This helper is for templates using configure scripts (not generated
# by the GNU autotools).
#
do_configure() {
	: ${configure_script:=./configure}

	${configure_script} ${configure_args}
}

do_build() {
	: ${make_cmd:=make}

	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
