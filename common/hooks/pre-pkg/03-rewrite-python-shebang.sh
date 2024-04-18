# This hook executes the following tasks:
#	- rewrites python shebangs with the corresponding python version

hook() {
	local pyver= shebang= off=

	if [ -d ${PKGDESTDIR}/usr/lib/python* ]; then
		pyver="$(find ${PKGDESTDIR}/usr/lib/python* -prune -type d | grep -o '[[:digit:]]\.[[:digit:]]\+$')"
	fi

	if [ -n "$python_version" ]; then
		pyver="$python_version"
	fi

	if [ "$python_version" = ignore ]; then
		return
	fi

	if [ -n "$pyver" ]; then
		default_shebang="#!/usr/bin/python${pyver%.*}"
	fi

	grep -rlIZ -m1 '^#!.*python' "${PKGDESTDIR}" |
		while IFS= read -r -d '' file; do
			[ ! -s "$file" ] && continue

			pyinterp=$(sed -n -E -e 2q -e 's@^#!.*([[:space:]]|/)(python([0-9](\.[0-9]+)?)?)([[:space:]]+.*|$)@\2@p' "$file")
			[ -z "$pyinterp" ] && continue

			pyver=${pyinterp#python}
			if [ -n "$pyver" ]; then
				shebang="#!/usr/bin/python${pyver%.*}"
			else
				shebang="$default_shebang"
			fi

			basefile=${file#$PKGDESTDIR}

			[ -n "$shebang" ] || msg_error "python_version missing in template: unable to convert shebang in $basefile\n"

			echo "   Shebang converted to '$shebang': $basefile"
			sed -i "1s@.*python.*@${shebang}@" -- "$file"
		done
}
