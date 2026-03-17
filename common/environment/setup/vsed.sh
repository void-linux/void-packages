# Helper function for calling sed on files and checking if the
# file is actually changed
#
# NOTE: this will not check if the input is valid, you can problably
# make it execute arbirtrary commands via passing '; cmd' to a vsed
# call.

vsed() {
	local files=() regexes=() OPTIND OPTSTRING="ie:" has_inline=

	eval set -- "$(getopt -s bash "$OPTSTRING" "$@")";

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

	for f in "${files[@]}"; do
		olddigest="$($XBPS_DIGEST_CMD "$f")"
		olddigest="${olddigest%% *}"

		for rx in "${regexes[@]}"; do
			sed -i "$f" -e "$rx" || {
				msg_red "$pkgver: vsed: sed call failed with regex \"$rx\" on file \"$f\"\n"
				return 1
			}

			newdigest="$($XBPS_DIGEST_CMD "$f")"
			newdigest="${newdigest%% *}"

			msgfunc=msg_warn
			if [ -n "$XBPS_STRICT" ]; then
				msgfunc=msg_error
			fi

			if [ "$olddigest" = "$newdigest" ]; then
				$msgfunc "$pkgver: vsed: regex \"$rx\" didn't change file \"$f\"\n"
			fi
			olddigest="${newdigest}"
		done
	done
}
