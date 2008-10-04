# This fixes the definitions that the perl binary uses to look at
# PKGFS_MASTERDIR and not PKGFS_DESTDIR!

$sed_cmd -e "s|$PKGFS_DESTDIR\/$pkgname-$version|$PKGFS_MASTERDIR|g" \
	$wrksrc/config.h > $wrksrc/config.h.in && \
$mv_cmd -f $wrksrc/config.h.in $wrksrc/config.h
