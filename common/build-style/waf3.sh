#
# This helper is for templates using WAF with python3 to build/install.
#
do_configure() {
	: ${configure_script:=waf}
	local cross_args

	if [[ $build_helper = *"qemu"* ]] && [ "$CROSS_BUILD" ]; then
		# If the qemu build helper is specified, use it for cross builds
		cross_args="--cross-compile --hostcc=${CC_FOR_BUILD}
		 --cross-execute=qemu-${XBPS_TARGET_QEMU_MACHINE}-static"
	fi

	PYTHON=/usr/bin/python3 python3 ${configure_script} configure \
		--prefix=/usr --libdir=/usr/lib${XBPS_TARGET_WORDSIZE} \
		${configure_args} ${cross_args}
}

do_build() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python3 python3 ${configure_script} build ${make_build_args}
}

do_install() {
	: ${configure_script:=waf}

	PYTHON=/usr/bin/python3 python3 ${configure_script} install --destdir=${DESTDIR} ${make_install_args}
}
