# This provides the extglob function to expand wildcards in the destdir

expand_destdir() {
	local glob_list= result= glob= file=

	for glob; do
		glob_list+=" $DESTDIR/$glob"
	done
	shopt -s extglob
	for file in $glob_list; do
		result+=" ${file#$DESTDIR/}"
	done
	shopt -u extglob
	echo $result
}
