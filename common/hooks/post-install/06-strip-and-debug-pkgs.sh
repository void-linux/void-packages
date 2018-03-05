# This hook executes the following tasks:
#	- strips ELF binaries/libraries
#	- generates -dbg pkgs

make_debug() {
	local dname= fname= dbgfile=

	[ -n "$nodebug" ] && return 0

	dname=$(echo "$(dirname $1)"|sed -e "s|${PKGDESTDIR}||g")
	fname="${1##*/}"
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
	fname="${1##*/}"
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
	printf "${pkgver} " >> ${_destdir}/rdeps
	rmdir --ignore-fail-on-non-empty "${PKGDESTDIR}/usr/lib" 2>/dev/null
	return 0
}

hook() {
	local fname= x= f= _soname= STRIPCMD=

	if [ -n "$nostrip" -o -n "$noarch" ]; then
		return 0
	fi

	STRIPCMD=/usr/bin/$STRIP

	find ${PKGDESTDIR} -type f | while read f; do
		if [[ $f =~ ^${PKGDESTDIR}/usr/lib/debug/ ]]; then
			continue
		fi

		fname=${f##*/}
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
				$STRIPCMD "$f"
				if [ $? -ne 0 ]; then
					msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
					return 1
				fi
				echo "   Stripped static executable: ${f#$PKGDESTDIR}"
			else
				make_debug "$f"
				$STRIPCMD "$f"
				if [ $? -ne 0 ]; then
					msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
					return 1
				fi
				echo "   Stripped executable: ${f#$PKGDESTDIR}"
				unset nopie_found
				for x in ${nopie_files}; do
					if [ "$x" = "${f#$PKGDESTDIR}" ]; then
						nopie_found=1
						break
					fi
				done
				if [ -z "$nopie" ] && [ -z "$nopie_found" ]; then
					msg_red "$pkgver: non-PIE executable found in PIE build: ${f#$PKGDESTDIR}\n"
					return 1
				fi
				attach_debug "$f"
			fi
			;;
		application/x-sharedlib*)
			chmod +w "$f"
			# shared library
			make_debug "$f"
			$STRIPCMD --strip-unneeded "$f"
			if [ $? -ne 0 ]; then
				msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
				return 1
			fi
			if file $f | grep -q "interpreter "; then
				echo "   Stripped position-independent executable: ${f#$PKGDESTDIR}"
			else
				echo "   Stripped library: ${f#$PKGDESTDIR}"
			fi
			attach_debug "$f"
			;;
		application/x-archive*)
			chmod +w "$f"
			$STRIPCMD --strip-debug "$f"
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
