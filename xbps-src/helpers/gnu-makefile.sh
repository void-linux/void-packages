#
# This helper is for templates using GNU Makefiles.
#
do_build() {
	if [ -z "$make_cmd" ]; then
		make_cmd=make
	fi
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	local target

	if [ -z "$make_install_target" ]; then
		target="DESTDIR=${DESTDIR} install"
	else
		target="${make_install_target}"
	fi
	if [ -z "$make_cmd" ]; then
		make_cmd=make
	fi
	${make_cmd} ${make_install_args} ${target}
}
