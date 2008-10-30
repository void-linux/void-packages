#
# This helper registers DTDs and XML/SGML catalogs through the
# xmlcatmgr application, as done in pkgsrc.
#

xmlcatmgr_cmd=$XBPS_MASTERDIR/bin/xmlcatmgr
sgml_catalog=$XBPS_MASTERDIR/share/sgml/catalog
xml_catalog=$XBPS_MASTERDIR/share/xml/catalog

if [ -x $xmlcatmgr_cmd -a -f $sgml_catalog -a -f $xml_catalog ]; then
	if [ -n "$sgml_entries" ]; then
		echo "=> Registering SGML catalogs for \`$pkgname-$version'."
		set -- ${sgml_entries}
		while [ $# -gt 0 ]; do
			$xmlcatmgr_cmd -sc $sgml_catalog add "$1" "$2" "$3"
			shift; shift; shift;
		done
	fi

	if [ -n "$xml_entries" ]; then
		echo "=> Registering XML catalogs for \`$pkgname-$version'."
		set -- ${xml_entries}
		while [ $# -gt 0 ]; do
			$xmlcatmgr_cmd -c $xml_catalog add "$1" "$2" "$3"
			shift; shift; shift;
		done
	fi
fi

unset xmlcatmgr_cmd sgml_catalog xml_catalog
