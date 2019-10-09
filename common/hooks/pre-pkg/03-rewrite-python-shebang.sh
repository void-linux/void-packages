# This hook executes the following tasks:
#	- rewrites python shebangs with the corresponding python version

hook() {
	local pyver= shebang= off=

	: ${pyver:=2}

	if [ -d ${PKGDESTDIR}/usr/lib/python* ]; then
		pyver="$(find ${PKGDESTDIR}/usr/lib/python* -prune -type d | grep -o '[[:digit:]]\.[[:digit:]]$')"
	fi

	if [ -n "$pycompile_version" ]; then
		pyver="$pycompile_version"
	fi

	if [ "$python_version" = "3" ]; then
		pyver="$python_version"
	fi

	shebang="#!/usr/bin/python${pyver%.*}"
	find "${PKGDESTDIR}" -type f -print0 | \
		xargs -0 grep -H -b -m 1 "^#!.*\([[:space:]]\|/\)python\([0-9]\.[0-9]\)\?\([[:space:]]\+\|$\)" -- | while IFS=: read -r f off _; do
		[ -z "$off" ] && continue
		echo "   Shebang converted to '$shebang': ${f#$PKGDESTDIR}"
		sed -i "1s@.*python.*@${shebang}@" -- "$f"
	done
}
