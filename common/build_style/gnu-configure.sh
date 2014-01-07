#
# This helper is for templates using GNU configure scripts.
#
do_configure() {
	: ${configure_script:=./configure}

	# Make sure that shared libraries are built with --as-needed.
	#
	# http://lists.gnu.org/archive/html/libtool-patches/2004-06/msg00002.html
	if [ -z "$broken_as_needed" ]; then
		sed -i "s/^\([ \t]*tmp_sharedflag\)='-shared'/\1='-shared -Wl,--as-needed'/" ${configure_script}
	fi
	# Automatically detect musl toolchains.
	for f in $(find ${wrksrc} -type f -name *config*.sub); do
		cp -f ${XBPS_CROSSPFDIR}/config.sub ${f}
	done
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
