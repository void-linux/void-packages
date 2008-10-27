# This fixes the definitions that the perl binary uses to look at
# prefix and not XBPS_DESTDIR/MASTERDIR.

if [ "$XBPS_DESTDIR" != "/xbps" ]; then
	sed -i -e "s|$XBPS_DESTDIR\/$pkgname-$version|/usr|g" $wrksrc/config.h
fi

sed -i -e "s|/usr/usr|/usr|g" $wrksrc/config.h

if [ "$XBPS_MASTERDIR" != "/" ]; then
	sed -i -e "s|$XBPS_MASTERDIR||g" $wrksrc/config.h
fi
