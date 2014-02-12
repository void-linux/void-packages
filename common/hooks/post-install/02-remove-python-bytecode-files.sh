# This hook removes python bytecode files (.py[co]).

hook() {
	msg_normal "$pkgver: removing python bytecode archives...\n"
	find ${PKGDESTDIR} -type f -name *.py[co] -delete
}
