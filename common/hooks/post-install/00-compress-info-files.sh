# This hook compresses info(1) files.

hook() {
	local f j dirat lnkat newlnk
	local fpattern="s|${PKGDESTDIR}||g;s|^\./$||g;/^$/d"
	#
	# Find out if this package contains info files and compress
	# all them with gzip.
	#
	if [ ! -f ${PKGDESTDIR}/usr/share/info/dir ]; then
		return 0
	fi
	# Always remove this file if curpkg is not texinfo.
	if [ "$pkgname" != "texinfo" ]; then
		rm -f ${PKGDESTDIR}/usr/share/info/dir
	fi

	find ${PKGDESTDIR}/usr/share/info -type f -follow | while read -r f; do
		j=$(echo "$f"|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		[ "$j" = "/usr/share/info/dir" ] && continue
		# Ignore compressed files.
		if  [[ "$j" =~ .*.gz$ ]]; then
			continue
		fi
		# Ignore non info files.
		if ! [[ "$j" =~ .*.info$ ]] && ! [[ "$j" =~ .*.info-[0-9]*$ ]]; then
			continue
		fi
		if [ -h ${PKGDESTDIR}/"$j" ]; then
			dirat="${j%/*}/"
			lnkat=$(readlink ${PKGDESTDIR}/"$j")
			newlnk="${j##*/}"
			rm -f ${PKGDESTDIR}/"$j"
			cd ${PKGDESTDIR}/"$dirat"
			ln -s "${lnkat}".gz "${newlnk}".gz
			continue
		fi
		echo "   Compressing info file: $j..."
		gzip -nfq9 ${PKGDESTDIR}/"$j"
	done
}
