# Sets up locale system settings from /etc/locale.conf.
#
_parse_lc_conf() {
	lineno=
	while read -r line || [ "$line" ]; do
		line="${line%%#*}"
		lineno="$(($lineno+1))"
		lc=$(expr "$line" : '^\([[:upper:]_]\+=\([[:alnum:][:digit:]\._-]\+\|"[[:print:][:digit:]\._-]"\)\)')
		if [ "$lc" ] && [ "$line" = "$lc" ]; then
			eval ": \${$lc}"
		elif [ "$line" ]; then
			echo "$1: invalid assignment on line $lineno" >&2
		fi
	done < "$1"
	unset lineno line lc
}

if [ -s /etc/locale.conf ]; then
	_parse_lc_conf /etc/locale.conf
fi

# define default LANG to C.UTF-8 if not already set
LANG="${LANG:-C.UTF-8}"

export LANG LANGUAGE LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
export LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
export LC_IDENTIFICATION
