# This hook removes python bytecode files (.py[co]).

hook() {
	find ${PKGDESTDIR} -type f -name '*.py[co]' -delete
}
