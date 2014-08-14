# This hook generates vcdiffs for repository data.

hook() {
	type -P xdelta3 > /dev/null || return 0

	find $XBPS_REPOSITORY -name "${XBPS_TARGET_MACHINE}-repodata.genVcdiff" | xargs -r sha256sum | \
		while read chk oldfile; do
			newfile=${oldfile/.genVcdiff/}

			if ! cmp -s "${newfile}" "${oldfile}"; then
				newdiff="${newfile}.${chk}.vcdiff"
				xdelta3 -q -f -e -s "${oldfile}" "${newfile}" "${newdiff}"
				for diff in ${newfile}.*.vcdiff; do
					[ "${diff}" = "${newdiff}" ] && continue;
					cp -- "${diff}" "${diff}.tmp"
					xdelta3 -q -f merge -m "${diff}.tmp" "${newdiff}" "${diff}"
					rm -- "${diff}.tmp"
				done
			fi

			# generate an empty diff to the new file
			newchk=`sha256sum ${newfile} | awk '{ print $1 }'`
			xdelta3 -q -f -e -s "${newfile}" "${newfile}" "${newfile}.${newchk}.vcdiff"
			rm -- "${oldfile}"
		done
}
