#
# Install the XML/SGML catalog files.
#

echo "=> Installing XML/SGML catalogs."

$chmod_cmd 644 $wrksrc/catalog.*
[ ! -d $PKGFS_SYSCONFDIR/sgml ] && $mkdir_cmd $PKGFS_SYSCONFDIR/sgml
[ ! -d $PKGFS_DESTDIR/$pkgname-$version/share/sgml ] && \
	 $mkdir_cmd $PKGFS_DESTDIR/$pkgname-$version/share/sgml
[ ! -d $PKGFS_SYSCONFDIR/xml ] && $mkdir_cmd $PKGFS_SYSCONFDIR/xml
[ ! -d $PKGFS_DESTDIR/$pkgname-$version/share/xml ] && \
	$mkdir_cmd $PKGFS_DESTDIR/$pkgname-$version/share/xml
[ ! -f $PKGFS_SYSCONFDIR/sgml/catalog ] && \
	$cp_cmd $wrksrc/catalog.etc.sgml $PKGFS_SYSCONFDIR/sgml/catalog
[ ! -f $PKGFS_SYSCONFDIR/xml/catalog ] && \
	$cp_cmd $wrksrc/catalog.etc.xml $PKGFS_SYSCONFDIR/xml/catalog
[ ! -f $PKGFS_DESTDIR/$pkgname-$version/share/sgml/catalog ] && \
	$cp_cmd $wrksrc/catalog.sgml \
	$PKGFS_DESTDIR/$pkgname-$version/share/sgml/catalog
[ ! -f $PKGFS_DESTDIR/$pkgname-$version/share/xml/catalog ] && \
	$cp_cmd $wrksrc/catalog.xml \
	$PKGFS_DESTDIR/$pkgname-$version/share/xml/catalog
