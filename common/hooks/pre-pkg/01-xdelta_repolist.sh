# this hook marks files which are about to change for generating vcdiffs

hook() {
	type -P xdelta3 > /dev/null || return 0

	env
	# create links to preserve old versions of repodata
	find $XBPS_REPOSITORY -name "${XBPS_TARGET_MACHINE}-repodata" | while read; do
		rm "${REPLY}.genVcdiff" || true
		cp "${REPLY}" "${REPLY}.genVcdiff"
	done
}
