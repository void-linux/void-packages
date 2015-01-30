# This hook executes the following tasks:
#	- strips ELF binaries/libraries
#	- generates -dbg pkgs

make_debug() {
	local dname= fname= dbgfile=

	[ -n "$nodebug" ] && return 0

	dname=$(echo "$(dirname $1)"|sed -e "s|${PKGDESTDIR}||g")
	fname="$(basename $1)"
	dbgfile="${dname}/${fname}"

	mkdir -p "${PKGDESTDIR}/usr/lib/debug/${dname}"
	$OBJCOPY --only-keep-debug --compress-debug-sections \
		"$1" "${PKGDESTDIR}/usr/lib/debug/${dbgfile}"
	if [ $? -ne 0 ]; then
		msg_red "${pkgver}: failed to create dbg file: ${dbgfile}\n"
		return 1
	fi
	chmod 644 "${PKGDESTDIR}/usr/lib/debug/${dbgfile}"
}

attach_debug() {
	local dname= fname= dbgfile=

	[ -n "$nodebug" ] && return 0

	dname=$(echo "$(dirname $1)"|sed -e "s|${PKGDESTDIR}||g")
	fname="$(basename $1)"
	dbgfile="${dname}/${fname}"

	$OBJCOPY --add-gnu-debuglink="${PKGDESTDIR}/usr/lib/debug/${dbgfile}" "$1"
	if [ $? -ne 0 ]; then
		msg_red "${pkgver}: failed to attach dbg to ${dbgfile}\n"
		return 1
	fi
}

create_debug_pkg() {
	local _pkgname= _destdir=

	[ -n "$nodebug" ] && return 0
	[ ! -d "${PKGDESTDIR}/usr/lib/debug" ] && return 0

	_pkgname="${pkgname}-dbg-${version}"
	_destdir="${XBPS_DESTDIR}/${XBPS_CROSS_TRIPLET}/${_pkgname}"
	mkdir -p "${_destdir}/usr/lib"
	mv ${PKGDESTDIR}/usr/lib/debug ${_destdir}/usr/lib
	if [ $? -ne 0 ]; then
		msg_red "$pkgver: failed to create debug pkg\n"
		return 1
	fi
	rmdir --ignore-fail-on-non-empty "${PKGDESTDIR}/usr/lib" 2>/dev/null
	return 0
}

hook() {
	local fname= x= f= _soname=

	if [ -n "$nostrip" -o -n "$noarch" ]; then
		return 0
	fi

	find ${PKGDESTDIR} -type f | while read f; do
		if [[ $f =~ ^/usr/lib/debug/ ]]; then
			continue
		fi

		fname=$(basename "$f")
		for x in ${nostrip_files}; do
			if [ "$x" = "$fname" ]; then
				found=1
				break
			fi
		done
		if [ -n "$found" ]; then
			unset found
			continue
		fi
		case "$(file -bi "$f")" in
		application/x-executable*)
			chmod +w "$f"
			if echo "$(file $f)" | grep -q "statically linked"; then
				# static binary
				$STRIP "$f"
				if [ $? -ne 0 ]; then
					msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
					return 1
				fi
				echo "   Stripped static executable: ${f#$PKGDESTDIR}"
			else
				make_debug "$f"
				$STRIP "$f"
				if [ $? -ne 0 ]; then
					msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
					return 1
				fi
				echo "   Stripped executable: ${f#$PKGDESTDIR}"
				attach_debug "$f"
			fi
			;;
		application/x-sharedlib*)
			chmod +w "$f"
			# shared library
			make_debug "$f"
			$STRIP --strip-unneeded "$f"
			if [ $? -ne 0 ]; then
				msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
				return 1
			fi
			echo "   Stripped library: ${f#$PKGDESTDIR}"
			attach_debug "$f"
			;;
		application/x-archive*)
			chmod +w "$f"
			$STRIP --strip-debug "$f"
			if [ $? -ne 0 ]; then
				msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
				return 1
			fi
			echo "   Stripped static library: ${f#$PKGDESTDIR}";;
		esac
	done
	create_debug_pkg
	return $?
}
