# This hook generates python bytecode files (.py[co]).

hook() {
	# start fresh, ensure we compile the python bytecode as we want it,
	# not as python3-installer or something else wants it
	if [ -d "${PKGDESTDIR}" ]; then
		find "${PKGDESTDIR}" -type f -name '*.py[co]' -delete
	fi

	local pycompile_version
	for d in "${PKGDESTDIR}"/usr/lib/python*; do
		if ! [ -d "$d" ]; then
			break
		fi
		pycompile_version="$(find "${PKGDESTDIR}"/usr/lib/python* -prune -type d | grep -o '[[:digit:]]\.[[:digit:]]\+$')"
		if [ -z "${pycompile_module}" ]; then
			pycompile_module="$(find "${PKGDESTDIR}"/usr/lib/python*/site-packages* -mindepth 1 -maxdepth 1 '!' -name '*.egg-info' '!' -name '*.dist-info' '!' -name '*.so' '!' -name '*.pth' -printf '%f ')"
		fi
		break
	done

	if [ -n "$python_version" ] && [ "$python_version" != ignore ]; then
		pycompile_version="${python_version}"
	fi

	if [ "$pycompile_version" = 3 ]; then
		pycompile_version="${py3_ver}"
	elif [ "$pycompile_version" = 2 ]; then
		pycompile_version="${py2_ver}"
	fi

	if [ -n "${pycompile_dirs}" ] || [ -n "${pycompile_module}" ]; then
		[ -n "$pycompile_version" ] || msg_error "$pkgver: byte-compilation is required, but python_version is not set\n"
	fi

	local sitelib="${PKGDESTDIR}/usr/lib/python${pycompile_version}/site-packages"

	# Starting with Python 3.5, compileall supports parallelism
	par=""
	if [ "${pycompile_version%%.*}" -gt 2 ]; then
		pycompile_minor="${pycompile_version#*.}"
		[ "${pycompile_minor}" = "${pycompile_version}" ] && pycompile_minor=""
		if [ -z "${pycompile_minor}" ] || ! [ "${pycompile_minor}" -lt 5 ] >/dev/null 2>&1; then
			par="-j0"
		fi
	fi

	for f in ${pycompile_dirs}; do
		echo "Byte-compiling python code in ${f}..."
		"python${pycompile_version}" -m compileall ${par} -s "$PKGDESTDIR" -f -q "./${f}"
	done

	for f in ${pycompile_module}; do
		echo "Byte-compiling python${pycompile_version} code for module ${f}..."
		"python${pycompile_version}" -m compileall ${par} -f -s "$PKGDESTDIR" -q "${sitelib}/${f}"
	done
}
