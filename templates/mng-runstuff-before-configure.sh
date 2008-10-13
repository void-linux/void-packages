#
# Automake'ify MNG.
#

cd $wrksrc &&	\
	$ln_cmd -sf makefiles/configure.in . && \
	$ln_cmd -sf makefiles/Makefile.am .

. $XBPS_TMPLHELPDIR/automake.sh
