#
# This helper is for Raku package templates.
#

do_check() {
	RAKULIB=lib ${make_check_pre} prove -r -e raku t/
}

do_install() {
	export RAKUDO_LOG_PRECOMP=1
	export RAKUDO_RERESOLVE_DEPENDENCIES=0
	raku-install-dist \
		--to=${DESTDIR}/usr/lib/raku/vendor \
		--for=vendor \
		--from=.
}
