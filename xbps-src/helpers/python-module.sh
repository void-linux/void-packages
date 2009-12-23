#
# This helper is for templates installing python modules.
#

do_install()
{
	if [ -z "$make_install_args" ]; then
		make_install_args="--prefix=/usr --root=$DESTDIR"
	fi

	cd ${wrksrc} || return 1
	sed -i 's|man/man1|share/man/man1|g' setup.py || return 1
	python setup.py install ${make_install_args} || return 1
}
