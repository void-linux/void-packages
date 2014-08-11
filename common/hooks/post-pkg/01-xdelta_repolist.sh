# This hook generates vcdiffs

hook() {
	set -x
	[ -z "$XBPS_GENERATE_VCDIFF" ] && return 0;

	find $XBPS_REPOSITORY -name '*.genVcdiff' | xargs -r sha256sum | \
		while read chk oldfile; do
			newfile=${oldfile/.genVcdiff/}

			if ! cmp -s "${newfile}" "${oldfile}"; then
				newdiff="${newfile}.${chk}.vcdiff"
				xdelta3 -D -R -f -e -s "${oldfile}" "${newfile}" "${newdiff}"
				for diff in ${newfile}.*.vcdiff; do
					[ "${diff}" = "${newdiff}" ] && continue;
					cp -- "${diff}" "${diff}.tmp"
					xdelta3 -f merge -m "${diff}.tmp" "${newdiff}" "${diff}"
					rm -- "${diff}.tmp"
				done
			fi

			rm -- "${oldfile}"
		done
}
