# Added support for NetBSD, as specified here:
# https://bugs.freedesktop.org/show_bug.cgi?id=17931

$cp_cmd -f $XBPS_TEMPLATESDIR/$pkgname-netbsd-pci.c \
	$XBPS_BUILDDIR/$pkgname-$version/src/netbsd_pci.c
cd $XBPS_BUILDDIR/$pkgname-$version && sh ./autogen.sh
