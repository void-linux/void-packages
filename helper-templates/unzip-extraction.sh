# Helper for templates using extract_sufx=".zip" that installs the unzip
# package if it's not available in PKGFS_MASTERDIR.

unzip_version="5.52"

# If unzip is already installed just return immediately.
check_installed_tmpl unzip-$unzip_version
if [ "$?" -ne 0 ]; then
	echo "=> unzip not installed, will install it."
	install_tmpl unzip-$unzip_version
	#
	# Continue with origin template that called us.
	#
	reset_tmpl_vars
	run_file ${origin_tmpl}
fi

unset unzip_version
unzip_cmd=$PKGFS_MASTERDIR/bin/unzip
