# Add the correct rpath flags to libpng-config.

$sed_cmd -e '/^L_opts=/s|-L\([    ]*[^    ]*\)"|-Wl,-R\1 -L\1"|g' \
	$wrksrc/libpng-config > $wrksrc/libpng-config.in
$mv_cmd -f $wrksrc/libpng-config.in $wrksrc/libpng-config
