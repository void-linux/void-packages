# This fixes the definitions that the perl binary uses to look at
# XBPS_MASTERDIR and not XBPS_DESTDIR!

$sed_cmd -e "s|$XBPS_DESTDIR\/$pkgname-$version|$XBPS_MASTERDIR|g" \
	$wrksrc/config.h > $wrksrc/config.h.in && \
$mv_cmd -f $wrksrc/config.h.in $wrksrc/config.h
