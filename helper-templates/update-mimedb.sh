#
# This helper updates shared-mime-info's database when a template
# requests this operation.
#
updatemimedb_cmd="$PKGFS_MASTERDIR/bin/update-mime-database"
updatemimedb_dir="$PKGFS_MASTERDIR/share/mime"

if [ -d "$PKGFS_MASTERDIR/share/mime" ]; then
	$updatemimedb_cmd $updatemimedb_dir >/dev/null && \
		echo "=> Updated shared-mime-info database."
fi

unset updatemimedb_cmd updatemimedb_dir
