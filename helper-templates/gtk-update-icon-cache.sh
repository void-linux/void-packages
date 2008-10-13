#
# This helper updates the GTK's theme icon cache as requested by
# any template.
#

gtkupdate_iconcache_cmd=$XBPS_MASTERDIR/bin/gtk-update-icon-cache
iconcache_theme_dir=$XBPS_MASTERDIR/share/icons/hicolor

if [ -x $gtkupdate_iconcache_cmd -a -d $iconcache_theme_dir ]; then
	$gtkupdate_iconcache_cmd -f -t $iconcache_theme_dir && \
		echo "=> Updated GTK's hicolor icon cache theme."
fi

unset gtkupdate_iconcache_cmd iconcache_theme_dir
