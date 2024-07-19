# This hook removes python bytecode files (.py[co]).

hook() {
    if [ -d "${PKGDESTDIR}" ]; then
        find ${PKGDESTDIR} -type f -name '*.py[co]' -delete
    fi
}
