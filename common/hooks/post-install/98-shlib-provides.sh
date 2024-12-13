# This hook executes the following tasks:
#	- generates shlib-provides file for xbps-create(1)

collect_sonames() {
	local _destdir="$1" f _soname _fname _pattern
	local _pattern="^[[:alnum:]]+(.*)+\.so(\.[0-9]+)*$"
	local _versioned_pattern="^[[:alnum:]]+(.*)+\.so(\.[0-9]+)+$"
	local _tmpfile=$(mktemp) || exit 1
	local _mainpkg="${2:-}"
	local _suffix="${3:-}"
	local _shlib_dir="${XBPS_STATEDIR}/shlib-provides"
	local _no_soname=$(mktemp) || exit 1

	mkdir -p "${_shlib_dir}" || exit 1
	if [ ! -d ${_destdir} ]; then
		rm -f ${_tmpfile}
		rm -f ${_no_soname}
		return 0
	fi


	# real pkg
	find ${_destdir} -type f -name "*.so*" | while read f; do
		_fname="${f##*/}"
		case "$(file -bi "$f")" in
		application/x-sharedlib*|application/x-pie-executable*)
			# shared library
			_soname=$(${OBJDUMP} -p "$f"|awk '/SONAME/{print $2}')
			if [ -n "$noshlibprovides" ]; then
				# register all shared lib for rt-deps between sub-pkg
				echo "${_fname}" >>${_no_soname}
				continue
			fi
			# Register all versioned sonames, and
			# unversioned sonames only when in libdir.
			if [[ ${_soname} =~ ${_versioned_pattern} ]] ||
			   [[ ${_soname} =~ ${_pattern} &&
			   	( -e ${_destdir}/usr/lib/${_fname} ||
				  -e ${_destdir}/usr/lib32/${_fname} ) ]]; then
				echo "${_soname}" >> ${_tmpfile}
				echo "   SONAME ${_soname} from ${f##${_destdir}}"
			else
				# register all shared lib for rt-deps between sub-pkg
				echo "${_fname}" >>${_no_soname}
			fi
			;;
		esac
	done

	for f in ${shlib_provides}; do
		echo "$f" >> ${_tmpfile}
	done
	if [ -s "${_tmpfile}" ]; then
		tr '\n' ' ' < "${_tmpfile}" > "${XBPS_STATEDIR}/${pkgname}${_suffix}-shlib-provides"
		echo >> "${XBPS_STATEDIR}/${pkgname}${_suffix}-shlib-provides"
		if [ "$_mainpkg" ]; then
			cp "${_tmpfile}" "${_shlib_dir}/${pkgname}.soname"
		fi
	fi
	if [ "$_mainpkg" ] && [ -s "${_no_soname}" ]; then
		mv "${_no_soname}" "${_shlib_dir}/${pkgname}.nosoname"
	else
		rm -f ${_no_soname}
	fi
	rm -f ${_tmpfile}
}

hook() {
	local _destdir32=${XBPS_DESTDIR}/${pkgname}-32bit-${version}
	local _mainpkg=yes
	local _pkg

	case "$pkgname" in
	*-32bit)
		_pkgname=${pkgname%-32bit}
		for _pkg in $sourcepkg $subpackages; do
			if [ "$_pkg" = "$_pkgname" ]; then
				_mainpkg=
				break
			fi
		done
		;;
	esac

	# native pkg
	collect_sonames ${PKGDESTDIR} $_mainpkg
	# 32bit pkg
	collect_sonames ${_destdir32} "" -32bit
}
