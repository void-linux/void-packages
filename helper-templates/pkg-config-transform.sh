#
# This helper will transform the pkg-config files with correct
# directories pointing at PKGFS_MASTERDIR specified in the config file.
#
pkgconfig_transform_file()
{
	local file="$1"

	[ -z "$file" ] && return 1

	$sed_cmd	\
		-e "s|^exec_prefix=$PKGFS_DESTDIR/$pkgname.*$|exec_prefix=\${prefix}|" \
		-e "s|-L\${libdir}|-L\${libdir} -Wl,-R\${libdir}|" \
		$file > $file.in && \
	$mv_cmd $file.in $file
	[ "$?" -eq 0 ] && \
		echo "=> Transformed pkg-config file: $(basename $file)."
}
