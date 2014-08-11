# this hook marks files which are about to change for generating vcdiffs

hook() {
	[ -z "$XBPS_GENERATE_VCDIFF" ] && return 0;

	# create links to preserve old versions of repodata
	find $XBPS_REPOSITORY -name '*-repodata' | \
		while read; do
			ln "${REPLY}" "${REPLY}.genVcdiff"
		done
}
