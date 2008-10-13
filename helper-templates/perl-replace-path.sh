#
# This helper transforms files with wrong perl path to the correct
# one pointing at XBPS_MASTERDIR/bin/perl.
#

perl_transform_file()
{
	local files="$@"

	[ -z "$files" ] && exit 1

	for f in ${files}; do
		[ ! -f $f ] && continue
		$sed_cmd -e "s|^#!.*/usr/bin/perl|#!$XBPS_MASTERDIR/bin/perl|" \
			$f > $f.in && $mv_cmd -f $f.in $f && \
		echo "=> Transformed $(basename $f) with correct path."
	done
}
