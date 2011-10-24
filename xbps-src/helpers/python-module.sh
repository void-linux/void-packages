#
# This helper is for templates installing python modules.
#
do_build() {
	python setup.py build ${make_build_args}
}

do_install() {
	if [ -z "$make_install_args" ]; then
		make_install_args="--prefix=/usr --root=$DESTDIR"
	fi
	python setup.py install ${make_install_args}
}
