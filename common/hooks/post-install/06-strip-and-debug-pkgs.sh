# This hook executes the following tasks:
#	- strips ELF binaries/libraries
#	- generates -dbg pkgs

make_debug() {
	local dname= fname= dbgfile=

	[ -n "$nodebug" ] && return 0

	dname=${1%/*}/ ; dname=${dname#$PKGDESTDIR}
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

	dname=${1%/*}/ ; dname=${dname#$PKGDESTDIR}
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
	printf "${pkgver} " >> ${XBPS_STATEDIR}/${pkgname}-dbg-rdeps
	rmdir --ignore-fail-on-non-empty "${PKGDESTDIR}/usr/lib" 2>/dev/null
	return 0
}

hook() {
	local fname= x= f= _soname= STRIPCMD=

	if [ -n "$nostrip" ]; then
		return 0
	fi

	STRIPCMD=/usr/bin/$STRIP

	find ${PKGDESTDIR} -type f | while read -r f; do
		if [[ $f =~ ^${PKGDESTDIR}/usr/lib/debug/ ]]; then
			continue
		fi

		fname=${f##*/}
		for x in ${nostrip_files}; do
			if [ "$x" = "$fname" -o "$x" = "${f#$PKGDESTDIR}" ]; then
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
			if [[ $(file $f) =~ "statically linked" ]]; then
				# static binary
				if ! $STRIPCMD "$f"; then
					msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
					return 1
				fi
				echo "   Stripped static executable: ${f#$PKGDESTDIR}"
			else
				make_debug "$f"
				if ! $STRIPCMD "$f"; then
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
		application/x-sharedlib*|application/x-pie-executable*)
			local type="$(file -b "$f")"
			if [[ $type =~ "no machine" ]]; then
				# using ELF as a container format (e.g. guile)
				echo "   Ignoring ELF file without machine set: ${f#$PKGDESTDIR}"
				continue
			fi

			chmod +w "$f"
			# shared library
			make_debug "$f"
			if ! $STRIPCMD --strip-unneeded "$f"; then
				msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
				return 1
			fi
			if [[ $type =~ "interpreter " ]]; then
				echo "   Stripped position-independent executable: ${f#$PKGDESTDIR}"
			else
				echo "   Stripped library: ${f#$PKGDESTDIR}"
			fi
			attach_debug "$f"
			;;
		application/x-archive*)
			chmod +w "$f"
			if ! $STRIPCMD --strip-debug "$f"; then
				msg_red "$pkgver: failed to strip ${f#$PKGDESTDIR}\n"
				return 1
			fi
			echo "   Stripped static library: ${f#$PKGDESTDIR}";;
		esac
	done
	create_debug_pkg
	return $?
}
