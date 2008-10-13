#
# This helper updates the pango modules file when the pango package
# has been properly installed and stowned.
#

pango_query_modules_cmd=$XBPS_MASTERDIR/bin/pango-querymodules
pango_query_modules_db=$XBPS_SYSCONFDIR/pango/pango.modules

if [ -x $pango_query_modules_cmd -a -w $pango_query_modules_db ]; then
	$pango_query_modules_cmd > $pango_query_modules_db
	[ "$?" -eq 0 ] && \
		echo "=> Updated Pango's $pango_query_modules_db modules file."
fi

unset pango_query_modules_cmd
unset pango_query_modules_db
