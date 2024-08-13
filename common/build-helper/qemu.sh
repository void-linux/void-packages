if [ "$CROSS_BUILD" ]; then
	export QEMU_LD_PREFIX=${XBPS_CROSS_BASE}
	if [[ $hostmakedepends != *"qemu-user"* ]]; then
		hostmakedepends+=" qemu-user"
	fi
fi

vtargetrun() {
	if [ "$CROSS_BUILD" ]; then
		"/usr/bin/qemu-${XBPS_TARGET_QEMU_MACHINE}-static" "$@"
	else
		"$@"
	fi
}
