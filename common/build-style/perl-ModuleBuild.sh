#
# This helper does the required steps to be able to build and install
# perl modules with the Module::Build method into the correct location.
#
# Required vars to be set by a template:
#
# 	build_style=perl-ModuleBuild
#
do_configure() {
	if [ -f Build.PL ]; then
		# When cross compiling Module::Build reads in the build flags from the host perl, not the target:
		# extract the target specific flags (the ones also set in perl’s template) from
		# the target perl configuration and use them to override Module::Build’s default
		_conf="${XBPS_CROSS_BASE}/usr/lib/perl5/core_perl/Config_heavy.pl"
		_optimize=$(sed -n "s;^optimize='\(.*\)';\1;p" $_conf)
		_ccflags=$(sed -n "s;^ccflags='\(.*\)';\1;p" $_conf)
		_lddlflags=$(sed -n "s;^lddlflags='\(.*\)';\1;p" $_conf)
		_ldflags=$(sed -n "s;^ldflags='\(.*\)';\1;p" $_conf)
		_archlibexp=$(sed -n "s;^archlibexp='\(.*\)';\1;p" $_conf)

		PERL_MM_USE_DEFAULT=1 PERL_MM_OPT="INSTALLDIRS=vendor DESTDIR='$DESTDIR'" \
			PERL_MB_OPT="--installdirs vendor --destdir '$DESTDIR'" \
			LD="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
			perl Build.PL --config optimize="$_optimize" --config ccflags="$_ccflags" \
			--config lddlflags="$_lddlflags" --config ldflags="$_ldflags" \
			--config archlibexp="${XBPS_CROSS_BASE}${_archlibexp}" \
			${configure_args} INSTALLDIRS=vendor
	else
		msg_error "$pkgver: cannot find Build.PL for perl module!\n"
	fi
}

do_build() {
	if [ ! -x ./Build ]; then
		msg_error "$pkgver: cannot find ./Build script!\n"
	fi
	LD="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" ./Build ${make_build_args}
}

do_check() {
	if [ ! -x ./Build ]; then
		msg_error "$pkgver: cannot find ./Build script!\n"
	fi
	./Build test
}

do_install() {
	if [ ! -x ./Build ]; then
		msg_error "$pkgver: cannot find ./Build script!\n"
	fi
	./Build ${make_install_args} install
}
