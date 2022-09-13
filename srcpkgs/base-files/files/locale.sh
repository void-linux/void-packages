# Sets up locale system settings from /etc/locale.conf.
#

if [ -z "$LANG" ]; then
	if [ -s /etc/locale.conf ]; then
		. /etc/locale.conf
	fi
fi

# define default LANG to C if not already defined
LANG=${LANG:-C}

export LANG LANGUAGE LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
export LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
export LC_INDENTIFICATION
