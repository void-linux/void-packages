#
# This helpers runs fc-cache after fontconfig has been installed,
# and update its list of fonts.
#

if [ -x /usr/bin/fc-cache ]; then
	/usr/bin/fc-cache -f
	[ "$?" -eq 0 ] && echo "=> Updated fontconfig fonts cache."
fi
