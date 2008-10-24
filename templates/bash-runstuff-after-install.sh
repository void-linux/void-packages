#
# Make /bin/bash -> /bin/sh symlink.
#

if [ -x $XBPS_DESTDIR/$pkgname-$version/bin/bash ]; then
	cd $XBPS_DESTDIR/$pkgname-$version/bin && ln -s bash sh
fi
