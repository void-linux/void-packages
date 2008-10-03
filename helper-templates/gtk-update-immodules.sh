#
# This helper updates GTK's gtk.immodules modules file every time
# a template requests this process.
#
gtk_version="2.0"
gtk_query_immodules_cmd=$PKGFS_MASTERDIR/bin/gtk-query-immodules-$gtk_version
gtk_immodules_db=$PKGFS_SYSCONFDIR/gtk-$gtk_version/gtk.immodules

if [ -x $gtk_query_immodules_cmd -a -w $gtk_immodules_db ]; then
	$gtk_query_immodules_cmd > $gtk_immodules_db
	[ "$?" -eq 0 ] && \
		echo "=> Updated GTK+ $(basename $gtk_immodules_db) modules file."
fi

unset gtk_version
unset gtk_query_immodules_cmd
unset gtk_immodules_db
