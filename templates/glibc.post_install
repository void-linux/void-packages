#
# Replace hardcoded path to bash.
# x86_64 arch: use /lib rather than /lib64 and make lib64 -> lib symlinks.
#

if [ -x $XBPS_DESTDIR/$pkgname-$version/usr/bin/ldd ]; then
	sed -i -e "s,$XBPS_MASTERDIR/bin/bash,/bin/bash,g" \
		$XBPS_DESTDIR/$pkgname-$version/usr/bin/ldd
fi

if [ "$xbps_machine" = "x86_64" ]; then
	sed -i '/RTLDLIST/s%/ld-linux.so.2 /lib64%%' \
		$XBPS_DESTDIR/$pkgname-$version/usr/bin/ldd
	cd $XBPS_DESTDIR/$pkgname-$version && ln -s lib lib64
	cd $XBPS_DESTDIR/$pkgname-$version/usr && ln -s lib lib64
fi
