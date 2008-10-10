# Replace hardcoded paths in XDG_DATA_DIRS.

$sed_cmd -e "s|/usr/local/share|$PKGFS_MASTERDIR/share|g" \
	$wrksrc/update-mime-database.c > $wrksrc/update-mime-database.c.in && \
$mv_cmd -f $wrksrc/update-mime-database.c.in $wrksrc/update-mime-database.c
