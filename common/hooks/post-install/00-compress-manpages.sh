# This hook compresses manual pages with gzip(1).

hook() {
	local fpattern="s|${PKGDESTDIR}||g;s|^\./$||g;/^$/d"
	local j f dirat lnkat newlnk

	if [ ! -d "${PKGDESTDIR}/usr/share/man" ]; then
		return 0
	fi

	find ${PKGDESTDIR}/usr/share/man -type f -follow | while read f
	do
		j=$(echo "$f"|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		if $(echo "$j"|grep -q '.*.gz$'); then
			continue
		fi
		if [ -h ${PKGDESTDIR}/"$j" ]; then
			dirat=$(dirname "$j")
			lnkat=$(readlink ${PKGDESTDIR}/"$j")
			newlnk=$(basename "$j")
			rm -f ${PKGDESTDIR}/"$j"
			cd ${PKGDESTDIR}/"$dirat"
			ln -s "${lnkat}".gz "${newlnk}".gz
			continue
		fi
		echo "   Compressing manpage: $j..."
		gzip -nfq9 ${PKGDESTDIR}/"$j"
	done
}
