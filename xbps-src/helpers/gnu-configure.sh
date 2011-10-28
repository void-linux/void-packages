#
# This helper is for templates using GNU configure script.
#

# This variable can be used for packages wanting to use common arguments
# to GNU configure scripts.
#
do_configure() {
	[ -z "$configure_script" ] && configure_script="./configure"
	${configure_script} ${CONFIGURE_SHARED_ARGS} ${configure_args}
}

# GNU configure scripts use make(1) to build/install.
. $XBPS_HELPERSDIR/gnu-makefile.sh
