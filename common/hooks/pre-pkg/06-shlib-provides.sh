# This hook executes the following tasks:
#	- generates shlib-provides file for xbps-create(1)

has_private_shlib() {
	local f="$1" _soname="$2"
	${OBJDUMP} -p "$f" | awk '
		/^Version definitions:/{v=1}
		!v{next}
		/_PRIVATE_API/{ print "yes"; exit}
		/^$/{exit}
	'
}

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
	{
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
				echo "${_soname}" >&3
				echo "   SONAME ${_soname} from ${f##${_destdir}}"
				if [ "$(has_private_shlib "$f")" ]; then
					_private="private:$_soname:${libprivate:-${version}}"
					echo "$_private" >&3
				fi
			fi
			;;
		esac
	done

	for f in ${shlib_provides}; do
		echo "$f" >&3
	done
	} 3>${_tmpfile}
	if [ -s "${_tmpfile}" ]; then
		sort <${_tmpfile} | xargs >${_destdir}/shlib-provides
	fi
	rm -f ${_tmpfile}
}

hook() {
	local _destdir32=${XBPS_DESTDIR}/${pkgname}-32bit-${version}

	if [ -n "$noshlibprovides" ]; then
		return 0
	fi

	# native pkg
	collect_sonames ${PKGDESTDIR}
	# 32bit pkg
	collect_sonames ${_destdir32}
}
