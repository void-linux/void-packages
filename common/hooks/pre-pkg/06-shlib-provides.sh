# This hook executes the following tasks:
#	- generates shlib-provides file for xbps-create(8)

collect_sonames() {
	local _destdir="$1" f _soname _fname _pattern
	local _pattern="^[[:alnum:]]+(.*)+\.so(\.[0-9]+)*$"
	local _versioned_pattern="^[[:alnum:]]+(.*)+\.so(\.[0-9]+)+$"
	local _tmpfile=$(mktemp) || exit 1

	if [ ! -d ${_destdir} ]; then
		rm -f ${_tmpfile}
		return 0
	fi

	# real pkg
	find ${_destdir} -type f -name "*.so*" | while read f; do
		_fname="${f##*/}"
		case "$(file -bi "$f")" in
		application/x-sharedlib*|application/x-pie-executable*)
			# shared library
			_soname=$(${OBJDUMP} -p "$f"|grep SONAME|awk '{print $2}')
			# Register all versioned sonames, and
			# unversioned sonames only when in libdir.
			if [[ ${_soname} =~ ${_versioned_pattern} ]] ||
			   [[ ${_soname} =~ ${_pattern} &&
			   	( -e ${_destdir}/usr/lib/${_fname} ||
				  -e ${_destdir}/usr/lib32/${_fname} ) ]]; then
				echo "${_soname}" >> ${_tmpfile}
				echo "   SONAME ${_soname} from ${f##${_destdir}}"
			fi
			;;
		esac
	done

	for f in ${shlib_provides}; do
		echo "$f" >> ${_tmpfile}
	done
	if [ -s "${_tmpfile}" ]; then
		tr '\n' ' ' < "${_tmpfile}" > ${_destdir}/shlib-provides
		echo >> ${_destdir}/shlib-provides
	fi
	rm -f ${_tmpfile}
}

# verify that shlibs listed in common/shlibs are actually provided by the package
verify_sonames() {
	local _destdir="$1" broken= mapshlibs pkgshlibs mappedshlibs
	mapshlibs="${XBPS_COMMONDIR}/shlibs"

	if [ ! -f ${_destdir}/shlib-provides ]; then
		return 0
	fi

	pkgshlibs="$(cat ${_destdir}/shlib-provides)"

	mappedshlibs="$(grep -E "[[:blank:]]${pkgname}" $mapshlibs)" || return 0

	set -- $mappedshlibs
	while [ $# -gt 0 ]
	do
		if [ "$($XBPS_UHELPER_CMD getpkgname "$2")" = ${pkgname} ]; then
			if [[ "${pkgshlibs}" != *"$1"* ]]; then
				msg_red "shlib '$1' isn't in shlib-provides for ${pkgname}\n"
				broken=1
			fi

			file="$(find ${_destdir} -name "$1")"
			if [ -z "$file" ]; then
				msg_red "file for shlib '$1' isn't in ${pkgname}\n"
			fi
		fi
		shift 2
	done

	return $broken
}

hook() {
	local _destdir32=${XBPS_DESTDIR}/${pkgname}-32bit-${version}

	if [ -z "$shlib_provides" -a "${archs// /}" = "noarch" -o -n "$noshlibprovides" ]; then
		return 0
	fi

	# native pkg
	collect_sonames ${PKGDESTDIR}
	# 32bit pkg
	collect_sonames ${_destdir32}

	verify_sonames ${PKGDESTDIR} || return 1
}
