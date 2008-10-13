#
# This helpers runs fc-cache after fontconfig has been installed,
# and update its list of fonts.
#

if [ -x $XBPS_MASTERDIR/bin/fc-cache ]; then
	$XBPS_MASTERDIR/bin/fc-cache -f
	[ "$?" -eq 0 ] && echo "=> Updated fontconfig fonts cache."
fi
