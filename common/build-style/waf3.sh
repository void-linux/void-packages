#
# This helper is for templates using WAF with python3 to build/install.
#
do_configure() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python3 python3 ${configure_script} configure --prefix=/usr ${configure_args}
}

do_build() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python3 python3 ${configure_script} build ${make_build_args}
}

do_install() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python3 python3 ${configure_script} install --destdir=${DESTDIR} ${make_install_args}
}
