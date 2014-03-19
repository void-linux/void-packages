# This hook creates a new PKGDESTDIR with 32bit files for x86_64.
#
# Variables that can be used in templates:
#	- lib32depends: if set, 32bit pkg will use this rather than "depends".
#	- lib32disabled: if set, no 32bit pkg will be created.
#	- lib32files: additional files to add to the 32bit pkg (abs paths, separated by blanks).
#	- lib32mode:
#		* if unset only files for libraries will be copied.
#		* if set to "full" all files will be copied.

hook() {
	local destdir32=${XBPS_DESTDIR}/${pkgname}-32bit-${version}

	# By default always enabled unless "lib32disabled" is set.
	if [ -n "$lib32disabled" ]; then
		return
	fi
	# This hook will only work when building for x86.
	if [ "$XBPS_TARGET_MACHINE" != "i686" ]; then
		return
	fi 
	# Ignore noarch pkgs.
	if [ -n "$noarch" ]; then
		return
	fi
	if [ -z "$lib32mode" ]; then
		# Library mode, copy only relevant files to new destdir.
		#
		# If /usr/lib does not exist don't continue...
		if [ ! -d ${PKGDESTDIR}/usr/lib ]; then
			return
		fi
		mkdir -p ${destdir32}/usr/lib32
		cp -a ${PKGDESTDIR}/usr/lib/* ${destdir32}/usr/lib32

		# Only keep shared libs, static libs, and pkg-config files.
		find "${destdir32}" -not \( \
			-name '*.pc' -or \
			-name '*.so' -or \
			-name '*.so.*' -or \
			-name '*.a' -or \
			-name '*.la' -or \
			-name '*.o' -or \
			-type d \
		\) -delete

		# Remove empty dirs.
		for f in $(find ${destdir32} -type d -empty|sort -r); do
			_dir="${f##${destdir32}}"
			[ -z "${_dir}" ] && continue
			rmdir --ignore-fail-on-non-empty -p "$f" &>/dev/null
		done

		# Switch pkg-config files to lib32.
		if [ -d ${destdir32}/usr/lib32/pkgconfig ]; then
			sed -e 's,/usr/lib,/usr/lib32,g' \
			    -e 's,${exec_prefix}/lib,${exec_prefix}/lib32,g' \
			    -i ${destdir32}/usr/lib32/pkgconfig/*.pc
		fi
	elif [ "$lib32mode" = "full" ]; then
		# Full 32bit mode; copy everything to new destdir.
		mkdir -p ${destdir32}
		cp -a ${PKGDESTDIR}/* ${destdir32}/
	fi
	if [ ! -d ${destdir32} ]; then
		return
	fi

	# If the rdeps file exist (runtime deps), copy and then modify it for
	# 32bit dependencies.
	trap - ERR

	: > ${destdir32}/rdeps

	if [ -s "$PKGDESTDIR/rdeps" ]; then
		if [ -n "$lib32depends" ]; then
			_deps="${lib32depends}"
		else
			_deps="$(cat ${PKGDESTDIR}/rdeps)"
		fi
		for f in ${_deps}; do
			unset pkgn pkgv _noarch _hasdevel

			pkgn="$($XBPS_UHELPER_CMD getpkgdepname $f)"
			if [ -z "${pkgn}" ]; then
				pkgn="$($XBPS_UHELPER_CMD getpkgname $f)"
				if [ -z "${pkgn}" ]; then
					msg_error "$pkgver: invalid dependency $f\n"
				fi
				pkgv="-$($XBPS_UHELPER_CMD getpkgversion ${f})"
			else
				pkgv="$($XBPS_UHELPER_CMD getpkgdepversion ${f})"
			fi
			# If dependency is noarch do not change it to 32bit.
			_noarch=$($XBPS_QUERY_CMD -R --property=architecture "$f")
			if [ "${_noarch}" = "noarch" ]; then
				printf "${pkgn}${pkgv} " >> ${destdir32}/rdeps
				continue
			fi
			printf "${pkgn}-32bit${pkgv} " >> $destdir32/rdeps
		done
	fi

	# Also install additional files set via "lib32files".
	for f in ${lib32files}; do
		echo "$pkgver: installing additional files: $f ..."
		_targetdir=${destdir32}/$(dirname ${f})
		mkdir -p ${_targetdir}
		cp -a ${PKGDESTDIR}/${f} ${_targetdir}
	done
	# If it's a development pkg add a dependency to the 64bit pkg.
	if [[ $pkgname =~ '-devel' ]]; then
		printf "${pkgver} " >> ${destdir32}/rdeps
	fi
	printf "\n" >> ${destdir32}/rdeps
}
