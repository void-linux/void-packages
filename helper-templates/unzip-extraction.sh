#
# This helper is used in templates using extract_sufx=".zip".
# This checks if unzip is installed and installs it if it's not
# and sets the unzip_cmd/extract_cmd variables appropiately.
#
unzip_version="5.52"

# Save pkgname before installing unzip.
save_pkgname=$pkgname

# If unzip is already installed just return immediately.
check_installed_tmpl unzip-$unzip_version
if [ "$?" -ne 0 ]; then
	echo "=> unzip not installed, will install it."
	install_tmpl unzip
	#
	# Continue with previous template that called us.
	#
	reset_tmpl_vars
	run_file $PKGFS_TEMPLATESDIR/$save_pkgname.tmpl
	check_tmpl_vars $save_pkgname
fi

unset save_pkgname
unset unzip_version

unzip_cmd=$PKGFS_MASTERDIR/bin/unzip
extract_cmd="$unzip_cmd -x $dfile -d $PKGFS_BUILDDIR"
