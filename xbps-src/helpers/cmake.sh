#
# This helper is for templates using cmake.
#
do_configure() {
	[ -z "$configure_script" ] && configure_script=cmake
	${configure_script} -DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release ${configure_args}
}

# cmake scripts use make(1) to build/install.
. $XBPS_HELPERSDIR/gnu-makefile.sh
