#
# This helper is for templates using configure scripts (not generated
# by the GNU autotools).
#

do_configure() {
	[ -z "$configure_script" ] && configure_script="./configure"
	${configure_script} ${configure_args}
}

# configure scripts use make(1) to build/install.
. $XBPS_HELPERSDIR/gnu-makefile.sh
