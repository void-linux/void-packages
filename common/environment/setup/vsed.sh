# Helper function for calling sed on files and checking if the
# file is actually changed
#
# NOTE: this will not check if the input is valid, you can problably
# make it execute arbirtrary commands via passing '; cmd' to a vsed
# call.

# This provides the extglob function to expand wildcards in the wrksrc
expand_wrksrc() {
	local result= glob= file=

	(
		set -f
		for glob in $@; do
			files=$(echo "${wrksrc}/${glob}")
			set +f
			for file in $files; do
				result+="${blank}${file#$wrksrc/}"
				blank=" "
			done
		done
		echo "$result"
	)
}

_vsed() {
	local files=() regexes=() OPTIND

	while getopts ":i:e:" opt; do
		case $opt in
			i) 
				for f in $(expand_wrksrc "$OPTARG"); do
					files+=("$f")
				done ;;
			e) regexes+=("$OPTARG") ;;
			*) ;;
		esac
	done

	if [ ${#files[@]} -eq 0 ]; then
		msg_red "$pkgver: vsed: no files specified with -i.\n"
		return 1
	fi

	if [ ${#regexes[@]} -eq 0 ]; then
		msg_red "$pkgver: vsed: no regexes specified with -e.\n"
		return 1
	fi

	for rx in "${regexes[@]}"; do
		for f in "${files[@]}"; do
			shasums="$(sha256sum "$f" 2>/dev/null | awk '{print $1}')"

			sed -i "$f" -e "$rx" || {
				msg_red "$pkgver: vsed: sed call failed with regex \"$rx\" on file \"$f\"\n"
				return 1
			}

			sha256sum="$(sha256sum "$f" 2>/dev/null)"

			if [ "$shasums" = "${sha256sum%% *}" ]; then
				msg_warn "$pkgver: vsed: regex \"$rx\" didn't change file \"$f\"\n"
			fi
		done
	done
}
