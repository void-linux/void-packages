#
# This helper runs the GNU autoconf tools and friends for a template.
# Optionally $automake_dir may be specified for a specific directory.
#

run_automake()
{
	$PKGFS_MASTERDIR/bin/aclocal
	$PKGFS_MASTERDIR/bin/libtoolize --automake
	$PKGFS_MASTERDIR/bin/automake -a --foreign -i
	$PKGFS_MASTERDIR/bin/autoconf
}

if [ -z "$automake_dir" ]; then
	cd $wrksrc && run_automake
else
	cd $wrksrc/$automake_dir && run_automake
fi
