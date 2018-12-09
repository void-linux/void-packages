# Checks for situations in which pycompile_module is required

hook() {
	if [ -n "$pycompile_module" ]; then
		pycompile_module="${pycompile_module// /$'\n'}"
	fi

	if [ -d $PKGDESTDIR/${py2_sitelib} ]; then
		for p in $(find $PKGDESTDIR/${py2_sitelib} -maxdepth 1 -not -iname '*.egg-info'); do

			if [ "$p" = "$PKGDESTDIR/$py2_sitelib"  ]; then
				continue
			fi

			if [ -n "$pycompile_module" ]; then
				if grep -q "^${p##*/}$" <<< "$pycompile_module"; then
					continue
				fi
			fi

			msg_warn "${pkgver}: ${p##*/} should be in pycompile_module\n"
		done
	fi

	if [ -d $PKGDESTDIR/${py3_sitelib} ]; then
		for p in $(find $PKGDESTDIR/${py3_sitelib} -maxdepth 1 -not -iname '*.egg-info'); do

			if [ "$p" = "$PKGDESTDIR/$py3_sitelib"  ]; then
				continue
			fi

			if [ -n "$pycompile_module" ]; then
				if grep -q "^${p##*/}$" <<< "$pycompile_module"; then
					continue
				fi
			fi

			msg_warn "${pkgver}: ${p##*/} should be in pycompile_module\n"
		done
	fi
}
