# This provides the extglob function to expand wildcards in the destdir

expand_destdir() {
	local result= glob= file=

	(
		set -f
		for glob in $@; do
			files=$(echo "${PKGDESTDIR}/${glob}")
			set +f
			for file in $files; do
				result+="${blank}${file#$PKGDESTDIR/}"
				blank=" "
			done
		done
		echo "$result"
	)
}
