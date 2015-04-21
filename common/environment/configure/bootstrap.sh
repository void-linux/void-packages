if [ -z "$CHROOT_READY" ]; then
	CFLAGS="-I${XBPS_MASTERDIR}/usr/include"
	LDFLAGS="-L${XBPS_MASTERDIR}/usr/lib"
fi
