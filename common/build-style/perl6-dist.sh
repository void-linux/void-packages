#
# This helper is for Rakudo Perl 6 package templates.
#

do_check() {
	PERL6LIB=lib prove -r -e perl6 t/
}

do_install() {
	export RAKUDO_LOG_PRECOMP=1
	export RAKUDO_RERESOLVE_DEPENDENCIES=0
	perl6-install-dist \
		--to=${DESTDIR}/usr/share/perl6/vendor \
		--for=vendor \
		--from=.
}
