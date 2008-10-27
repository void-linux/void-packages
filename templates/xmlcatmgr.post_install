#
# Install the XML/SGML catalog files.
#

echo "=> Installing XML/SGML catalogs."

$chmod_cmd 644 $wrksrc/catalog.*
[ ! -d $XBPS_SYSCONFDIR/sgml ] && $mkdir_cmd $XBPS_SYSCONFDIR/sgml
[ ! -d $XBPS_DESTDIR/$pkgname-$version/share/sgml ] && \
	 $mkdir_cmd $XBPS_DESTDIR/$pkgname-$version/share/sgml
[ ! -d $XBPS_SYSCONFDIR/xml ] && $mkdir_cmd $XBPS_SYSCONFDIR/xml
[ ! -d $XBPS_DESTDIR/$pkgname-$version/share/xml ] && \
	$mkdir_cmd $XBPS_DESTDIR/$pkgname-$version/share/xml
[ ! -f $XBPS_SYSCONFDIR/sgml/catalog ] && \
	$cp_cmd $wrksrc/catalog.etc.sgml $XBPS_SYSCONFDIR/sgml/catalog
[ ! -f $XBPS_SYSCONFDIR/xml/catalog ] && \
	$cp_cmd $wrksrc/catalog.etc.xml $XBPS_SYSCONFDIR/xml/catalog
[ ! -f $XBPS_DESTDIR/$pkgname-$version/share/sgml/catalog ] && \
	$cp_cmd $wrksrc/catalog.sgml \
	$XBPS_DESTDIR/$pkgname-$version/share/sgml/catalog
[ ! -f $XBPS_DESTDIR/$pkgname-$version/share/xml/catalog ] && \
	$cp_cmd $wrksrc/catalog.xml \
	$XBPS_DESTDIR/$pkgname-$version/share/xml/catalog
