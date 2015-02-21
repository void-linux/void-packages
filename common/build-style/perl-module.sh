#
# This helper does the required steps to be able to build and install
# perl modules that use MakeMaker into the correct location.
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
			msg_error "*** ERROR couldn't find $perlmkf, aborting ***\n"
		fi

		cd $wrksrc
		PERL_MM_USE_DEFAULT=1 GCC="$CC" CC="$CC" LD="$CC" \
			OPTIMIZE="$CFLAGS" \
			CFLAGS="$CFLAGS -I${XBPS_CROSS_BASE}/usr/include" \
			LDFLAGS="$LDFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
			LDDLFLAGS="-shared $CFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
			perl Makefile.PL ${configure_args} INSTALLDIRS=vendor
	fi

	for i in "$perl_configure_dirs"; do
		perlmkf="$wrksrc/$i/Makefile.PL"
		if [ -f $perlmkf ]; then
			cd $wrksrc/$i
			PERL_MM_USE_DEFAULT=1 GCC="$CC" CC="$CC" LD="$CC" \
				OPTIMIZE="$CFLAGS" \
				CFLAGS="$CFLAGS -I${XBPS_CROSS_BASE}/usr/include" \
				LDFLAGS="$LDFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
				LDDLFLAGS="-shared $CFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
				perl Makefile.PL ${make_build_args} INSTALLDIRS=vendor
		else
			msg_error "*** ERROR: couldn't find $perlmkf, aborting **\n"
		fi
	done
}

do_build() {
	: ${make_cmd:=make}

	${make_cmd} CC="$CC" LD="$CC" CFLAGS="$CFLAGS" OPTIMIZE="$CFLAGS" \
		LDFLAGS="$LDFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
		LDDLFLAGS="-shared $CFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
		${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
