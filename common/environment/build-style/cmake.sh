if [ "$CHROOT_READY" ]; then
	if [ "$pkgname" != cmake ]; then
		hostmakedepends+=" cmake"
	fi
	if [ "${make_cmd:-ninja}" = ninja ]; then
		hostmakedepends+=" ninja"
	fi
fi

export CTEST_OUTPUT_ON_FAILURE=TRUE
