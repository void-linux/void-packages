# This fixes the definitions that the perl binary uses to look at
# prefix and not XBPS_DESTDIR/MASTERDIR.

$sed_cmd -i								\
	-e "s|$XBPS_DESTDIR\/$pkgname-$version|/usr|g"			\
	-e "s|$XBPS_MASTERDIR||g"					\
	$wrksrc/config.h
