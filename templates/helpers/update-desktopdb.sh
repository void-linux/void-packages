#
# This helper update's desktop-file-utils desktop database for any
# package that requests this operation.
#

update_desktopdb_cmd=$XBPS_MASTERDIR/bin/update-desktop-database
desktopdb_dir=$XBPS_MASTERDIR/share/applications

if [ -x $update_desktopdb_cmd -a -d $desktopdb_dir ]; then
	$update_desktopdb_cmd $desktopdb_dir && \
		echo "=> Updated desktop database directory."
fi

unset update_desktopdb_cmd desktopdb_dir
