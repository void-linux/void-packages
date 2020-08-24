if [ ! "$CHROOT_READY" ]; then
	case "$sourcepkg,$XBPS_TARGET_LIBC" in
	kernel-libc-headers,*|glibc,*|musl,*) ;;
	*,musl)	makedepends+=" musl-devel" ;;
	*,*)	makedepends+=" glibc-devel" ;;
	esac
fi
