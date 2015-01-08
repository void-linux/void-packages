#
# This helper is for templates using GNU configure scripts.
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

	make_install_args+=" DESTDIR=${DESTDIR}"

	${make_cmd} ${make_install_args} ${make_install_target}
}
