# This hook creates a new PKGDESTDIR with 32bit libraries for x86_64.
#
# XXX remaining issues:
#	- Conditionalized for now with "lib32" template var.
#	- due to ${pkgname} -> ${pkgname}32 renaming, some pkgs have wrong deps
#	  (noarch pkgs, dependencies without shlibs).

hook() {
	local destdir32=${XBPS_DESTDIR}/${pkgname}32-${version}

	if [ -z "$lib32" ]; then
		return
	fi
	# This hook will only work when building for x86.
	if [ "$XBPS_MACHINE" != "i686" ]; then
		return
	fi 
	# Ignore noarch pkgs.
	if [ -n "$noarch" ]; then
		return
	fi
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

	# If the rdeps file exist (runtime deps), copy and then modify it for
	# 32bit dependencies.
	trap - ERR

	if [ -s "$PKGDESTDIR/rdeps" ]; then
		: > $destdir32/rdeps
		for f in $(cat ${PKGDESTDIR}/rdeps); do
			pkgn="$($XBPS_UHELPER_CMD getpkgdepname $f)"
			if [ -z "${pkgn}" ]; then
				pkgn="$($XBPS_UHELPER_CMD getpkgname $f)"
				if [ -z "${pkgn}" ]; then
					msg_error "$pkgver: invalid dependency $f\n"
				fi
				pkgv="$($XBPS_UHELPER_CMD getpkgversion ${f})"
			else
				pkgv="$($XBPS_UHELPER_CMD getpkgdepversion ${f})"
			fi
			echo "${pkgn}32${pkgv}" >> $destdir32/rdeps
		done
	fi

	# If it's a development pkg add a dependency to the 64bit pkg.
	if [[ $pkgname =~ '-devel' ]]; then
		echo "${pkgver}" >> $destdir32/rdeps
	fi
}
