#
# This helper is for templates using WAF to build/install.
#
do_configure() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python2 python2 ${configure_script} configure \
		--prefix=/usr --libdir=/usr/lib${XBPS_TARGET_WORDSIZE} ${configure_args}
}

do_build() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python2 python2 ${configure_script} build ${make_build_args}
}

do_install() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python2 python2 ${configure_script} install --destdir=${DESTDIR} ${make_install_args}
}
