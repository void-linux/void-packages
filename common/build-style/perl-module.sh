#
# This helper does the required steps to be able to build and install
# perl modules that use MakeMaker into the correct location.
#
# Required vars to be set by a template:
#
# 	build_style=perl-module
#
# Optionally if the module needs more directories to be configured other
# than $XBPS_BUILDDIR/$wrksrc/$build_wrksrc, one can use (relative to
# $wrksrc/$build_wrksrc):
#
#	perl_configure_dirs="blob/bob foo/blah"
#
do_configure() {
	local perlmkf

	local perlprefix=${XBPS_STATEDIR}/perlprefix-${XBPS_TARGET_MACHINE}
	mkdir -p $perlprefix
	if [ -d "$XBPS_CROSS_BASE/usr/lib/perl5/core_perl" ]; then
		cp "$XBPS_CROSS_BASE/usr/lib/perl5/core_perl/Config"*.p? $perlprefix
		cp "$XBPS_CROSS_BASE/usr/lib/perl5/core_perl/Errno.pm" $perlprefix
		sed -i -e "s;archlibexp => '\(.*\)';archlibexp => '${XBPS_CROSS_BASE}\1';" \
			${perlprefix}/Config.pm
		sed -i -e "s;^archlibexp='\(.*\)';archlibexp='${XBPS_CROSS_BASE}\1';" \
			${perlprefix}/Config_heavy.pl
	else
		cp "/usr/lib/perl5/core_perl/Config"*.p? $perlprefix
		cp "/usr/lib/perl5/core_perl/Errno.pm" $perlprefix
	fi
	export PERL5LIB=$perlprefix

	if [ -f "${wrksrc}/${build_wrksrc:+$build_wrksrc/}Makefile.PL" ]; then
		sed -i "s,/usr/include,${XBPS_CROSS_BASE}/usr/include,g" \
		"${wrksrc}/${build_wrksrc:+$build_wrksrc/}Makefile.PL"
	fi

	if [ -z "$perl_configure_dirs" ]; then
		perlmkf="$wrksrc/${build_wrksrc:+$build_wrksrc/}Makefile.PL"
		if [ ! -f "$perlmkf" ]; then
			msg_error "*** ERROR couldn't find $perlmkf, aborting ***\n"
		fi

		cd "$wrksrc/${build_wrksrc:+$build_wrksrc}"
		PERL_MM_USE_DEFAULT=1 GCC="$CC" CC="$CC" LD="$CC" \
			OPTIMIZE="$CFLAGS" \
			CFLAGS="$CFLAGS -I${XBPS_CROSS_BASE}/usr/include" \
			LDFLAGS="$LDFLAGS -L${XBPS_CROSS_BASE}/usr/lib -lperl" \
			LDDLFLAGS="-shared $CFLAGS -L${XBPS_CROSS_BASE}/usr/lib" \
			perl -I. Makefile.PL ${configure_args} INSTALLDIRS=vendor
	fi

	for i in ${perl_configure_dirs}; do
		perlmkf="$wrksrc/${build_wrksrc:+$build_wrksrc/}$i/Makefile.PL"
		if [ -f "$perlmkf" ]; then
			cd "$wrksrc/${build_wrksrc:+$build_wrksrc/}$i"
			PERL_MM_USE_DEFAULT=1 GCC="$CC" CC="$CC" LD="$CC" \
				OPTIMIZE="$CFLAGS" \
				CFLAGS="$CFLAGS -I${XBPS_CROSS_BASE}/usr/include" \
				LDFLAGS="$LDFLAGS -L${XBPS_CROSS_BASE}/usr/lib -lperl" \
				LDDLFLAGS="-shared $CFLAGS -L${XBPS_CROSS_BASE}/usr/lib -lperl" \
				perl -I. Makefile.PL ${make_build_args} INSTALLDIRS=vendor
		else
			msg_error "*** ERROR: couldn't find $perlmkf, aborting **\n"
		fi
	done
}

do_build() {
	: ${make_cmd:=make}

	${make_cmd} CC="$CC" LD="$CC" CFLAGS="$CFLAGS" OPTIMIZE="$CFLAGS" \
		LDFLAGS="$LDFLAGS -L${XBPS_CROSS_BASE}/usr/lib -lperl" \
		LDDLFLAGS="-shared $CFLAGS -L${XBPS_CROSS_BASE}/usr/lib -lperl" \
		${makejobs} ${make_build_args} ${make_build_target}
}

do_check() {
	: ${make_cmd:=make}
	: ${make_check_target:=test}

	${make_check_pre} ${make_cmd} ${makejobs} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
