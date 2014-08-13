# this hook marks files which are about to change for generating vcdiffs

hook() {
	type -P xdelta3 > /dev/null || return 0

	# create links to preserve old versions of repodata
	find $XBPS_REPOSITORY -name '*-repodata' | while read; do
		ln "${REPLY}" "${REPLY}.genVcdiff"
	done
}
