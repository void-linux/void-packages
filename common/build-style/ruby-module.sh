#
# This helper is for templates installing ruby modules.
#

do_install() {
	local _vendorlibdir=$(ruby -e 'puts RbConfig::CONFIG["vendorlibdir"]')

	if [ "$XBPS_WORDSIZE" != "$XBPS_TARGET_WORDSIZE" ]; then
		_vendorlibdir="${_vendorlibdir//lib$XBPS_WORDSIZE/lib$XBPS_TARGET_WORDSIZE}"
	fi

	LANG=C ruby install.rb --destdir=${DESTDIR} --sitelibdir=${_vendorlibdir} ${make_install_args}
}
