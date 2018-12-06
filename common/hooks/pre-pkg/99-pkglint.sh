# This hook checks for common issues related to void.

hook() {
	local error=0 filename= rev= libname= conflictPkg= conflictFile=
	local conflictRev= ignore= found= mapshlibs=$XBPS_COMMONDIR/shlibs

	set +E

	# Check for forbidden directories that are symlinks in void.
	for f in bin sbin lib lib32; do
		if [ -d ${PKGDESTDIR}/${f} ]; then
			msg_red "${pkgver}: /${f} directory is not allowed, use /usr/${f}.\n"
			error=1
		fi
	done

	if [ -d ${PKGDESTDIR}/usr/sbin ]; then
		msg_red "${pkgver}: /usr/sbin directory is not allowed, use /usr/bin.\n"
		error=1
	fi
	
	for f in sys dev home root run var/run tmp usr/lib64 usr/local; do
		if [ -d ${PKGDESTDIR}/${f} ]; then
			msg_red "${pkgver}: /${f} directory is not allowed, remove it!\n"
			error=1
		fi
	done

	# Check that configuration files really exist.
	for f in $(expand_destdir "${conf_files}"); do
		if [ ! -f "${PKGDESTDIR}/${f}" ]; then
			msg_red "${pkgver}: '$f' configuration file not in PKGDESTDIR!\n"
			error=1
		fi
	done

	# Check for bash completions in etc/bash_completion.d
	# should be on usr/share/bash-completion/completions
	if [ -d ${PKGDESTDIR}/etc/bash_completion.d ]; then
		msg_red "${pkgver}: /etc/bash_completion.d is forbidden. Use /usr/share/bash-completion/completions\n"
		error=1
	fi

	# Prevent packages from installing to these paths in etc, they should use
	# their equivalent in usr/lib
	for f in udev/{rules.d,hwdb.d} modprobe.d sysctl.d; do
		if [ -d ${PKGDESTDIR}/etc/${f} ]; then
			msg_red "${pkgver}: /etc/${f} is forbidden. Use /usr/lib/${f}\n"
			error=1
		fi
	done

	# Likewise with the comment above but for usr/share
	for f in X11/xorg.conf.d gconf/schemas; do
		if [ -d ${PKGDESTDIR}/etc/${f} ]; then
			msg_red "${pkgver}: /etc/${f} is forbidden. Use /usr/share/${f}\n"
			error=1
		fi
	done

	if [ -d ${PKGDESTDIR}/etc/dracut.conf.d ]; then
		msg_red "${pkgver}: /etc/dracut.conf.d is forbidden. Use /usr/lib/dracut/dracut.conf.d\n"
		error=1
	fi

	# Forbid empty packages unless build_style=meta
	if [ "$build_style" != "meta" ]; then
		if [ "$(find $PKGDESTDIR/* -maxdepth 1 -type d 2>/dev/null)" = "" ]; then
			msg_red "${pkgver}: PKGDESTDIR is empty and build_style != meta\n"
			error=1
		fi
	fi

	if [ $error -gt 0 ]; then
		msg_error "${pkgver}: cannot continue with installation!\n"
	fi

	# Check for missing shlibs and SONAME bumps.
	if [ ! -s "${PKGDESTDIR}/shlib-provides" ]; then
		return 0
	fi

	for filename in $(cat ${PKGDESTDIR}/shlib-provides); do
		rev=${filename#*.so.}
		libname=${filename%.so*}
		_shlib=$(echo "$libname"|sed -E 's|\+|\\+|g')
		_pkgname=$(echo "$pkgname"|sed -E 's|\+|\\+|g')
		if [ "$rev" = "$filename" ]; then
			_pattern="^${_shlib}\.so[[:blank:]]+${_pkgname}-[^-]+_[0-9]+"
		else
			_pattern="^${_shlib}\.so\.[0-9]+(.*)[[:blank:]]+${_pkgname}-[^-]+_[0-9]+"
		fi
		grep -E "${_pattern}" $mapshlibs | { \
			while read conflictFile conflictPkg ignore; do
				found=1
				conflictRev=${conflictFile#*.so.}
				if [ -n "$ignore" -a "$ignore" != "$XBPS_TARGET_MACHINE" ]; then
					continue
				elif [ "$rev" = "$conflictRev" ]; then
					continue
				elif [[ ${rev}.* =~ $conflictRev ]]; then
					continue
				fi
				msg_red "${pkgver}: SONAME bump detected: ${libname}.so.${conflictRev} -> ${libname}.so.${rev}\n"
				msg_red "${pkgver}: please update common/shlibs with this line: \"${libname}.so.${rev} ${pkgver}\"\n"
				msg_red "${pkgver}: all reverse dependencies should also be revbumped to be rebuilt against ${libname}.so.${rev}:\n"
				_revdeps=$($XBPS_QUERY_XCMD -Rs ${libname}.so -p shlib-requires|awk '{print $1}')
				for x in ${_revdeps}; do
					msg_red "   ${x%:}\n"
				done
				msg_error "${pkgver}: cannot continue with installation!\n"
			done
			# Try to match provided shlibs in virtual packages.
			for f in ${provides}; do
				_vpkgname="$($XBPS_UHELPER_CMD getpkgname ${f} 2>/dev/null)"
				_spkgname="$(grep "^${filename}" $mapshlibs | awk '{print $2}')"
				_libpkgname="$($XBPS_UHELPER_CMD getpkgname ${_spkgname} 2>/dev/null)"
				if [ -z "${_spkgname}" -o  -z "${_libpkgname}" ]; then
					continue
				fi
				if [ "${_vpkgname}" = "${_libpkgname}" ]; then
					found=1
					break
				fi
			done;
			if [ -z "$found" ]; then
				_myshlib="${libname}.so"
				[ "${_myshlib}" != "${rev}" ] && _myshlib+=".${rev}"
				msg_warn "${pkgver}: ${_myshlib} not found in common/shlibs!\n"
			fi;
		}
	done
}
