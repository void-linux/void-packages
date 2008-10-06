#
# This helper rebuilds the fonts.dir and fonts.scale files in a
# directory specified by a template.
#

[ -z "$fonts_dir" ] && return 1
[ ! -d "$fonts_dir" ] && $mkdir_cmd -p $fonts_dir

mkfontdir_cmd=$PKGFS_MASTERDIR/bin/mkfontdir
mkfontscale_cmd=$PKGFS_MASTERDIR/bin/mkfontscale

if [ -x $mkfontdir_cmd -a -x $mkfontscale_cmd ]; then
	save_path=$(pwd -P 2>/dev/null)
	cd $fonts_dir && $mkfontdir_cmd && $mkfontscale_cmd
	if [ "$?" -eq 0 ]; then
		echo "=> Updated $fonts_dir/fonts.dir."
		echo "=> Updated $fonts_dir/fonts.scale."
	fi
	cd $save_path
	unset save_path
fi

unset fonts_dir
unset mkfontdir_cmd
unset mkfontscale_cmd
