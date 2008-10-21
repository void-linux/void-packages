#
# Rebuild dynamic linker's cache after building glibc.
#
$XBPS_DESTDIR/$pkgname-$version/sbin/ldconfig -C $XBPS_SYSCONFDIR/ld.so.cache
$XBPS_DESTDIR/$pkgname-$version/sbin/ldconfig
