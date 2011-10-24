#
# This helper does the required steps to be able to build and install
# perl modules into the correct location.
#
# Required vars to be set by a template:
#
# 	build_style=perl-module
#
# Optionally if the module needs more directories to be configured other
# than $XBPS_BUILDDIR/$wrksrc, one can use (relative to $wrksrc):
#
#	perl_configure_dirs="blob/bob foo/blah"
#
do_configure() {
	local perlmkf

	if [ -z "$perl_configure_dirs" ]; then
		perlmkf="$wrksrc/Makefile.PL"
		if [ ! -f $perlmkf ]; then
			echo "*** ERROR couldn't find $perlmkf, aborting"
			exit 1
		fi

		cd $wrksrc && \
			PERL_MM_USE_DEFAULT=1 perl Makefile.PL \
			${make_build_args} INSTALLDIRS=vendor
	fi

	for i in "$perl_configure_dirs"; do
		perlmkf="$wrksrc/$i/Makefile.PL"
		if [ -f $perlmkf ]; then
			cd $wrksrc/$i && PERL_MM_USE_DEFAULT=1 \
				perl Makefile.PL ${make_build_args} \
				INSTALLDIRS=vendor
		else
			echo -n "*** ERROR: couldn't find $perlmkf"
			echo ", aborting ***"
			exit 1
		fi
	done
}

# Perl modules use standard make(1) to install.
. ${XBPS_HELPERSDIR}/gnu-makefile.sh
