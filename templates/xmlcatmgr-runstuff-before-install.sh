#
# Create XML and SGML catalogs once built.
#

echo "=> Creating SGML catalogs..."
$wrksrc/xmlcatmgr -sc $wrksrc/catalog.etc.sgml create
$wrksrc/xmlcatmgr -sc $wrksrc/catalog.sgml create
$wrksrc/xmlcatmgr -sc $wrksrc/catalog.etc.sgml add CATALOG	\
	$PKGFS_MASTERDIR/share/sgml/catalog
echo "=> Creating XML catalogs..."
$wrksrc/xmlcatmgr -c $wrksrc/catalog.etc.xml create
$wrksrc/xmlcatmgr -c $wrksrc/catalog.xml create
$wrksrc/xmlcatmgr -c $wrksrc/catalog.etc.xml add nextCatalog	\
	$PKGFS_MASTERDIR/share/xml/catalog
