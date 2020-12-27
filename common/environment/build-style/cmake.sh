if [ "$CHROOT_READY" ]; then
	if [[ "$hostmakedepends" != *"cmake-bootstrap"* ]]; then
		hostmakedepends+=" cmake"
	fi
fi
