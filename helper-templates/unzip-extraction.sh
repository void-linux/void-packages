#
# This helper is used in templates using extract_sufx=".zip".
# This checks if unzip is installed and installs it if it's not
# and sets the unzip_cmd/extract_cmd variables appropiately.
#
# If unzip is already installed just return immediately.

if [ ! -x "$XBPS_MASTERDIR/bin/unzip" ]; then
	unzip_version="5.52"

	# Save pkgname before installing unzip.
	save_pkgname=$pkgname

	check_installed_pkg unzip $unzip_version
	if [ $? -ne 0 ]; then
		echo "=> \`\`$pkg´´ package requires unzip for extraction."
		#
		# Install dependencies required by unzip.
		#
		install_builddeps_required_pkg unzip-$unzip_version
		#
		# Install the unzip package now.
		#
		install_pkg unzip
		#
		# Continue with previous template that called us.
		#
		reset_tmpl_vars
		setup_tmpl $save_pkgname
	fi

	unset save_pkgname
	unset unzip_version
fi

unzip_cmd=$XBPS_MASTERDIR/bin/unzip
extract_cmd="$unzip_cmd -x $dfile -d $XBPS_BUILDDIR"
