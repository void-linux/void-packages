#!/bin/sh
#
# Startup script for widelands to recognize the user's LANG setting, if any.

WL_DATA="/usr/share/widelands"
WL_LOCALE="$WL_DATA/locale"
WL_LANG="$LANG"
[ -z "$WL_LANG" ] && WL_LANG="en_US.UTF-8"

exec /usr/share/widelands/widelands --datadir="$WL_DATA" --localedir="$WL_LOCALE" --language="$WL_LANG"
