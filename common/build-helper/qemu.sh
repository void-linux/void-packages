if [ "$CROSS_BUILD" ]; then
	export QEMU_LD_PREFIX=${XBPS_CROSS_BASE}
	hostmakedepends+=" qemu-user-${XBPS_TARGET_QEMU_MACHINE/x86_64/amd64}"
fi

vtargetrun() {
	if [ "$CROSS_BUILD" ]; then
		"/usr/bin/qemu-${XBPS_TARGET_QEMU_MACHINE}" "$@"
	else
		"$@"
	fi
}
