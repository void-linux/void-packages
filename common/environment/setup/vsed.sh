# Helper function for calling sed on files and checking if the
# file is actually changed
#
# NOTE: this will not check if the input is valid, you can problably
# make it execute arbirtrary commands via passing '; cmd' to a vsed
# call.

vsed() {
	local files=() regexes=() OPTIND OPTSTRING="ie:" has_inline=

	eval set -- $(getopt -s bash "$OPTSTRING" "$@");

	while getopts "$OPTSTRING" opt; do
		case $opt in
			i) has_inline=1 ;;
			e) regexes+=("$OPTARG") ;;
			*) ;;
		esac
	done

	if ! [ "$has_inline" ]; then
		msg_red "$pkgver: vsed: you must specify -i.\n"
		return 1
	fi

	shift $(($OPTIND - 1))

	if [ ${#regexes[@]} -eq 0 ] && [ $# -ge 2 ]; then
		regexes+=("$1")
		shift
	fi

	if [ ${#regexes[@]} -eq 0 ]; then
		msg_red "$pkgver: vsed: no regexes specified.\n"
		return 1
	fi

	for i; do
		files+=("$i")
	done

	if [ ${#files[@]} -eq 0 ]; then
		msg_red "$pkgver: vsed: no files specified.\n"
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
