if [ -z "$CHROOT_READY" ]; then
	if [ -d $XBPS_MASTERDIR/usr/include ]; then
		CFLAGS+=" -I${XBPS_MASTERDIR}/usr/include"
	fi
	if [ -d $XBPS_MASTERDIR/usr/lib ]; then
		LDFLAGS+=" -L${XBPS_MASTERDIR}/usr/lib -Wl,-rpath-link=${XBPS_MASTERDIR}/usr/lib"
	fi
fi
