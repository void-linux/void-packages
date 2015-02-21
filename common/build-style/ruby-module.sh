#
# This helper is for templates installing ruby modules.
#

do_install() {
	local _vendorlibdir=$(ruby -e 'puts RbConfig::CONFIG["vendorlibdir"]')

	ruby install.rb --destdir=${DESTDIR} --sitelibdir=${_vendorlibdir} ${make_install_args}
}
