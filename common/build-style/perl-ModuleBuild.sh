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
		PERL_MM_USE_DEFAULT=1 PERL_MM_OPT="INSTALLDIRS=vendor DESTDIR='$DESTDIR'" \
			PERL_MB_OPT="--installdirs vendor --destdir '$DESTDIR'" \
			LD="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
			perl Build.PL ${configure_args} INSTALLDIRS=vendor
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
