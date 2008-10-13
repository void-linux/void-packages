#
# This helper updates shared-mime-info's database when a template
# requests this operation.
#
updatemimedb_cmd="$XBPS_MASTERDIR/bin/update-mime-database"
updatemimedb_dir="$XBPS_MASTERDIR/share/mime"

if [ -d "$XBPS_MASTERDIR/share/mime" ]; then
	$updatemimedb_cmd $updatemimedb_dir >/dev/null && \
		echo "=> Updated shared-mime-info database."
fi

unset updatemimedb_cmd updatemimedb_dir
