# Helper function for calling rm on files and prints a warning if the
# file doesn't exist.

vrm() {
	local ARGS recursive broken
	if [ "$1" = "-r" ]; then
		recursive=yes
		ARGS+=" -r"
		shift
	fi

	msgfunc=msg_warn
	if [ -n "$XBPS_STRICT" ]; then
		msgfunc=msg_red
	fi
	for file in "$@"; do
		if [ "$recursive" ] && ! [ -d "$file" ]; then
			if [ -n "$XBPS_STRICT" ]; then
				broken=yes
			fi
			$msgfunc "$pkgver: vrm: $file is not a directory\n"
		elif [ -e "$file" ]; then
			rm $ARGS "$file"
		else
			if [ -n "$XBPS_STRICT" ]; then
				broken=yes
			fi
			$msgfunc "$pkgver: vrm: $file doesn't exist\n"
		fi
	done
	if [ "$broken" ]; then
		return 1
	fi
}
