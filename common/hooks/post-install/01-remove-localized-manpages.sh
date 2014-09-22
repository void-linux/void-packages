# This hook removes localized man(1) files

hook() {
	local section mandir=${PKGDESTDIR}/usr/share/man

	for section in ${mandir}/*; do
		if ! [ -d ${section} ]; then
			continue
		fi

		case ${section} in
			${mandir}/man?)
				continue;;
		esac

		rm -rf ${section}
	done
}
