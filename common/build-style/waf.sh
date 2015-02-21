#
# This helper is for templates using WAF to build/install.
#
do_configure() {
	python waf configure --prefix=/usr ${configure_args}
}

do_build() {
	python waf build ${make_build_args}
}

do_install() {
	python waf install --destdir=${DESTDIR} ${make_install_args}
}
