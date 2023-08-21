if [ "$CHROOT_READY" ]; then
	if [ "$pkgname" != cmake-bootstrap ]; then
		hostmakedepends+=" cmake-bootstrap"
	fi
	if [ "${make_cmd:-ninja}" = ninja ]; then
		hostmakedepends+=" ninja"
	fi
fi

export CTEST_OUTPUT_ON_FAILURE=TRUE
PATH="$PATH:/usr/libexec/xbps-src/bin"
