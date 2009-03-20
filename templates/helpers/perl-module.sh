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

# Override the paths to get desired results.
: ${_arch:=$(uname -m)}
: ${perl_thrmulti:=${_arch}-linux-thread-multi}
: ${perl_cmd:=$XBPS_MASTERDIR/usr/bin/perl}
: ${PERL_DESTDIR:=$XBPS_MASTERDIR}
: ${PERL_PREFIX:=$PERL_DESTDIR/usr}
: ${PERL_DPREFIX:=${DESTDIR}/usr}
: ${PERL_VERSION:=5.10.0}
: ${PERL_LDDLFLAGS:=--whole-archive -shared -L$XBPS_MASTERDIR/lib}
: ${PERL_SITELIBEXP:=$PERL_DPREFIX/lib/perl5/site_perl/$PERL_VERSION}
: ${PERL_SITEARCHEXP:=$PERL_SITELIBEXP/$perl_thrmulti}
: ${PERL_SITEPREFIX:=$PERL_PREFIX}
: ${PERL_INSTALLPRIVLIB:=$PERL_DPREFIX/lib/perl5/$PERL_VERSION}
: ${PERL_INSTALLSITELIB:=$PERL_DPREFIX/lib/perl5/site_perl/$PERL_VERSION}
: ${PERL_INSTALLARCHLIB:=$PERL_DPREFIX/lib/perl5/$PERL_VERSION/$perl_thrmulti}
: ${PERL_INSTALLSITEARCH:=$PERL_SITELIBEXP}
: ${PERL_INSTALLBIN:=$PERL_DPREFIX/bin}
: ${PERL_INSTALLSITEBIN:=$PERL_INSTALLBIN}
: ${PERL_INSTALLSCRIPT:=$PERL_DPREFIX/bin}
: ${PERL_INSTALLSITESCRIPT:=$PERL_INSTALLSCRIPT}
: ${PERL_INSTALLMAN1DIR:=$PERL_DPREFIX/share/man/man1}
: ${PERL_INSTALLSITEMAN1DIR=$PERL_INSTALLMAN1DIR}
: ${PERL_INSTALLMAN3DIR:=$PERL_DPREFIX/share/man/man3}
: ${PERL_INSTALLSITEMAN3DIR:=$PERL_INSTALLMAN3DIR}
: ${PERL_PERLLIB:=$PERL_PREFIX/lib/perl5/$PERL_VERSION}
: ${PERL_ARCHLIB:=$PERL_PREFIX/lib/perl5/$PERL_VERSION/$perl_thrmulti}
: ${PERL_INC:=$PERL_PREFIX/lib/perl5/$PERL_VERSION/$perl_thrmulti/CORE}

: ${PERL_MAKE_VARS:=LDFLAGS=$LDFLAGS LDDLFLAGS=$PERL_LDDLFLAGS \
	SITELIBEXP=$PERL_SITELIBEXP SITEARCHEXP=$PERL_SITEARCHEXP \
	PERLPREFIX=$PERL_DESTDIR SITEPREFIX=$PERL_SITEPREFIX \
	INSTALLPRIVLIB=$PERL_INSTALLPRIVLIB \
	INSTALLSITELIB=$PERL_INSTALLSITELIB \
	INSTALLARCHLIB=$PERL_INSTALLARCHLIB \
	INSTALLSITEARCH=$PERL_INSTALLSITEARCH \
	INSTALLBIN=$PERL_INSTALLBIN \
	INSTALLSITEBIN=$PERL_INSTALLSITEBIN \
	INSTALLSCRIPT=$PERL_INSTALLSCRIPT \
	INSTALLSITESCRIPT=$PERL_INSTALLSITESCRIPT \
	INSTALLMAN1DIR=$PERL_INSTALLMAN1DIR \
	INSTALLSITEMAN1DIR=$PERL_INSTALLSITEMAN1DIR \
	INSTALLMAN3DIR=$PERL_INSTALLMAN3DIR \
	INSTALLSITEMAN3DIR=$PERL_INSTALLSITEMAN3DIR \
	PERL_LIB=$PERL_PERLLIB PERL_ARCHLIB=$PERL_ARCHLIB}

perl_module_build()
{
	local builddir="$wrksrc"
	local perlmkf=

	if [ -z "$perl_configure_dirs" ]; then
		perlmkf="$builddir/Makefile.PL"
		if [ ! -f $perlmkf ]; then
			echo "*** ERROR couldn't find $perlmkf, aborting"
			exit 1
		fi

		cd $builddir && \
			$perl_cmd Makefile.PL ${PERL_MAKE_VARS} $make_build_args
		if [ "$?" -ne 0 ]; then
			echo "*** ERROR building perl module for $pkgname ***"
			exit 1
		fi
	fi

	for i in "$perl_configure_dirs"; do
		perlmkf="$builddir/$i/Makefile.PL"
		if [ -f $perlmkf ]; then
			cd $builddir/$i && \
				$perl_cmd Makefile.PL \
				${PERL_MAKE_VARS} $make_build_args
			[ "$?" -ne 0 ] && exit 1
		else
			echo -n "*** ERROR: couldn't find $perlmkf"
			echo ", aborting ***"
			exit 1
		fi
	done
}
