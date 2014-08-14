# this hook marks files which are about to change for generating vcdiffs

hook() {
	type -P xdelta3 > /dev/null || return 0

	# create links to preserve old versions of repodata
	find $XBPS_REPOSITORY -name "${XBPS_TARGET_MACHINE}-repodata" | while read; do
		( rm "${REPLY}.genVcdiff" 2>/dev/null ) || true
		cp "${REPLY}" "${REPLY}.genVcdiff"
	done
}
