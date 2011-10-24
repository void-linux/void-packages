#
# This helper is for templates using WAF to build/install.
#
do_configure() {
	if [ -z "$configure_script" ]; then
		configure_script="./waf"
	fi
	${configure_script} configure --prefix=/usr ${configure_args}
}

do_build() {
	if [ -z "$make_cmd" ]; then
		make_cmd="./waf"
	fi
	${make_cmd} build ${make_build_args}
}

do_install() {
	if [ -z "$make_cmd" ]; then
		make_cmd="./waf"
	fi
	if [ -z "$make_install_args" ]; then
		make_install_args="--destdir=$DESTDIR"
	fi
	${make_cmd} install ${make_install_args}
}
