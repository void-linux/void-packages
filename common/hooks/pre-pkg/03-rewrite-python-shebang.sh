# This hook executes the following tasks:
#	- rewrites python shebangs with the corresponding python version

hook() {
	local pyver= shebang= off=

	if [ -d ${PKGDESTDIR}/usr/lib/python* ]; then
		pyver="$(find ${PKGDESTDIR}/usr/lib/python* -prune -type d | grep -o '[[:digit:]]\.[[:digit:]]$')"
	fi

	if [ -n "$python_version" ]; then
		pyver="$python_version"
	fi

	if [ -n "$pyver" ]; then
		shebang="#!/usr/bin/python${pyver%.*}"
	fi

	find "${PKGDESTDIR}" -type f -print0 | \
		while IFS= read -r -d '' file; do
			[ ! -s "$file" ] && continue
			[ -z "$(sed -n -E -e 2q -e '/^#!.*([[:space:]]|\/)python([0-9]\.[0-9])?([[:space:]]+|$)/p' "$file")" ] && continue
			[ -n "$shebang" ] || msg_error "cannot convert shebang, set python_version\n"
			echo "   Shebang converted to '$shebang': ${file#$PKGDESTDIR}"
			sed -i "1s@.*python.*@${shebang}@" -- "$file"
		done
}
