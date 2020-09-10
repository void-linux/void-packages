# This hook removes localized man(1) files

hook() {
	local section mandir=${PKGDESTDIR}/usr/share/man

	for section in ${mandir}/*; do
		if ! [ -d ${section} ]; then
			continue
		fi

		case ${section} in
			${mandir}/man[0-9n]|${mandir}/man[013][fp])
				continue;;
			${mandir}/cat[0-9n]|${mandir}/cat[013][fp])
				continue;;
		esac

		rm -rf ${section}
	done
}
