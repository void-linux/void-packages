#
# This helper updates GTK's gdk-pixbug.loaders modules file every time
# a template requests this process.
#
gtk_version="2.0"
gdk_pixbuf_query_cmd=$XBPS_MASTERDIR/bin/gdk-pixbuf-query-loaders
gdk_pixbuf_db=$XBPS_SYSCONFDIR/gtk-$gtk_version/gdk-pixbuf.loaders

if [ -x $gdk_pixbuf_query_cmd -a -w $gdk_pixbuf_db ]; then
	$gdk_pixbuf_query_cmd > $gdk_pixbuf_db
	[ "$?" -eq 0 ] && \
		echo "=> Updated GTK+ $(basename $gdk_pixbuf_db) modules file."
fi

unset gtk_version
unset gdk_pixbuf_query_cmd
unset gdk_pixbuf_dbfile
