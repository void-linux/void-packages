#!/bin/sh
shortname=$(echo $LANG | cut -b1-2)
if [ -d /usr/share/netsurf/$shortname ]; then
	/usr/bin/netsurf-gtk3 "$@"
else
	LANG=en_US /usr/bin/netsurf-gtk3 "$@"
fi
exit $?
