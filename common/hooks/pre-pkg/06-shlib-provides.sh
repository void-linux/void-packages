# This hook executes the following tasks:
#	- generates shlib-provides file for xbps-create(8)

collect_sonames() {
	local _destdir="$1" f _soname _fname _pattern
	local _pattern="^[[:alnum:]]+(.*)+\.so(\.[0-9]+)*$"
	local _tmpfile="$(mktemp)"

	if [ ! -d ${_destdir} ]; then
		rm -f ${_tmpfile}
		return 0
	fi

	# real pkg
	find ${_destdir} -type f | while read f; do
		_fname=$(basename "$f")
		case "$(file -bi "$f")" in
		application/x-sharedlib*)
			# shared library
			_soname=$(${OBJDUMP} -p "$f"|grep SONAME|awk '{print $2}')
			if [[ ${_soname} =~ ${_pattern} ]]; then
				if [ ! -e ${_destdir}/usr/lib/${_fname} -a \
				     ! -e ${_destdir}/usr/lib32/${_fname} ]; then
					continue
				fi
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
		cat ${_tmpfile} | tr '\n' ' ' > ${_destdir}/shlib-provides
		echo >> ${_destdir}/shlib-provides
	fi
	rm -f ${_tmpfile}
}

hook() {
	local _destdir32=${XBPS_DESTDIR}/${pkgname}-32bit-${version}

	if [ -n "$noarch" ]; then
		return 0
	fi

	# native pkg
	collect_sonames ${PKGDESTDIR}
	# 32bit pkg
	collect_sonames ${_destdir32}
}
