# This hook creates a new PKGDESTDIR with 32bit files for x86_64.
#
# Variables that can be used in templates:
#	- lib32depends: if set, 32bit pkg will use this rather than "depends".
#	- lib32disabled: if set, no 32bit pkg will be created.
#	- lib32files: additional files to add to the 32bit pkg (abs paths, separated by blanks).
#	- lib32symlinks: makes a symlink from lib32 to lib of the specified file (basename).
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
	if [ -z "$lib32mode" ]; then
		# Library mode, copy only relevant files to new destdir.
		#
		# If /usr/lib does not exist don't continue...
		# except for devel packages, for which empty 32bit package will be created
		if ! [ -d ${PKGDESTDIR}/usr/lib ] && ! [[ ${pkgname} == *-devel ]]; then
			return
		fi

		mkdir -p ${destdir32}/usr/lib32
		if [ -d ${PKGDESTDIR}/usr/lib ]; then
			cp -a ${PKGDESTDIR}/usr/lib/* ${destdir32}/usr/lib32
		fi

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
		while IFS= read -r -d '' f; do
			_dir="${f##${destdir32}}"
			[ -z "${_dir}" ] && continue
			rmdir --ignore-fail-on-non-empty -p "$f" &>/dev/null
		done < <(find ${destdir32} -type d -empty -print0 | sort -uz)

		# Switch pkg-config files to lib32.
		if [ -d ${destdir32}/usr/lib32/pkgconfig ]; then
			sed -e 's,/usr/lib$,/usr/lib32,g' \
			    -e 's,${exec_prefix}/lib$,${exec_prefix}/lib32,g' \
			    -i ${destdir32}/usr/lib32/pkgconfig/*.pc
		fi
	elif [ "$lib32mode" = "full" ]; then
		# Full 32bit mode; copy everything to new destdir.
		mkdir -p ${destdir32}
		cp -a ${PKGDESTDIR}/* ${destdir32}/
		# remove symlink
		if [ -h ${destdir32}/usr/lib32 ]; then
			rm ${destdir32}/usr/lib32
		fi
		# if /usr/lib dir exists move it to lib32.
		if [ -d ${destdir32}/usr/lib ]; then
			mv ${destdir32}/usr/lib ${destdir32}/usr/lib32
		fi
	fi
	if [[ ${pkgname} == *-devel ]]; then
		mkdir -p ${destdir32}
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
			_deps="$(<${PKGDESTDIR}/rdeps)"
		fi
		for f in ${_deps}; do
			unset found pkgn pkgv _shprovides

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
			# If dependency is a development pkg switch it to 32bit.
			if [[ $pkgn == *-devel ]]; then
				echo "   RDEP: $f -> ${pkgn}-32bit${pkgv} (development)"
				printf "${pkgn}-32bit${pkgv} " >> ${destdir32}/rdeps
				continue
			fi
			# If dependency does not have "shlib-provides" do not
			# change it to 32bit.
			for x in ${subpackages}; do
				if [ "$x" = "$pkgn" ]; then
					found=1
					break
				fi
			done
			if [ -z "$found" ]; then
				# Dependency is not a subpkg, check shlib-provides
				# via binpkgs.
				_shprovides="$($XBPS_QUERY_CMD -R --property=shlib-provides "$pkgn")"
				if [ -n "${_shprovides}" ]; then
					echo "   RDEP: $f -> ${pkgn}-32bit${pkgv} (shlib-provides)"
					printf "${pkgn}-32bit${pkgv} " >> ${destdir32}/rdeps
				else
					echo "   RDEP: $f -> ${pkgn}${pkgv} (no shlib-provides)"
					printf "${pkgn}${pkgv} " >> ${destdir32}/rdeps
				fi
			else
				if [ -s ${XBPS_DESTDIR}/${pkgn}-${version}/shlib-provides ]; then
					# Dependency is a subpkg; check if it provides any shlib
					# and convert to 32bit if true.
					echo "   RDEP: $f -> ${pkgn}-32bit${pkgv} (subpkg, shlib-provides)"
					printf "${pkgn}-32bit${pkgv} " >> ${destdir32}/rdeps
				else
					echo "   RDEP: $f -> ${pkgn}${pkgv} (subpkg, no shlib-provides)"
					printf "${pkgn}${pkgv} " >> ${destdir32}/rdeps
				fi
			fi
		done
	fi

	# Also install additional files set via "lib32files".
	for f in ${lib32files}; do
		echo "$pkgver: installing additional files: $f ..."
		_targetdir=${destdir32}/${f%/*}/
		mkdir -p ${_targetdir/\/usr\/lib/\/usr\/lib32}
		cp -a ${PKGDESTDIR}/${f} ${_targetdir/\/usr\/lib/\/usr\/lib32}
	done
	# Additional symlinks to the native libdir.
	for f in ${lib32symlinks}; do
		echo "$pkgver: symlinking $f to the native libdir..."
		if [ "${f%/*}" != "${f}" ]; then
			mkdir -p ${destdir32}/usr/lib{,32}/${f%/*}/
		else
			mkdir -p ${destdir32}/usr/lib{,32}/
		fi
		ln -sfr ${destdir32}/usr/lib32/$f ${destdir32}/usr/lib/$f
	done
	# If it's a development pkg add a dependency to the 64bit pkg.
	if [[ $pkgn == *-devel ]]; then
		echo "   RDEP: ${pkgver}"
		printf "${pkgver} " >> ${destdir32}/rdeps
	fi
	printf "\n" >> ${destdir32}/rdeps
}
