if [ "$CHROOT_READY" ]; then
	hostmakedepends+=" cmake"
	if [ "${make_cmd:-ninja}" = ninja ]; then
		hostmakedepends+=" ninja"
	fi
fi

export CTEST_OUTPUT_ON_FAILURE=TRUE
