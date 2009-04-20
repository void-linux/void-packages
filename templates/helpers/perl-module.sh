#
# This helper does the required steps to be able to build and install
# perl modules into the correct location.
#
# Required vars to be set by a template:
#
# 	build_style=perl_module
#
# Optionally if the module needs more directories to be configured other
# than $XBPS_BUILDDIR/$wrksrc, one can use (relative to $wrksrc):
#
#	perl_configure_dirs="blob/bob foo/blah"
#

perl_module_build()
{
	local perlmkf=

	if [ -z "$perl_configure_dirs" ]; then
		perlmkf="$wrksrc/Makefile.PL"
		if [ ! -f $perlmkf ]; then
			echo "*** ERROR couldn't find $perlmkf, aborting"
			exit 1
		fi

		cd $wrksrc && perl Makefile.PL ${make_build_args}
		if [ "$?" -ne 0 ]; then
			echo "*** ERROR building perl module for $pkgname ***"
			exit 1
		fi
	fi

	for i in "$perl_configure_dirs"; do
		perlmkf="$wrksrc/$i/Makefile.PL"
		if [ -f $perlmkf ]; then
			cd $wrksrc/$i && perl Makefile.PL ${make_build_args}
			[ "$?" -ne 0 ] && exit 1
		else
			echo -n "*** ERROR: couldn't find $perlmkf"
			echo ", aborting ***"
			exit 1
		fi
	done
}
