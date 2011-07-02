#-
# Copyright (c) 2008-2011 Juan Romero Pardines.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-

install_pkg_from_repos()
{
	local cmd rval pkgdepname pkg="$1"

	pkgdepname=$($XBPS_PKGDB_CMD getpkgdepname "$pkg")
	cmd="${fakeroot_cmd} ${fakeroot_cmd_args} ${XBPS_BIN_CMD} -Ay install"

	msg_normal "'$pkgname': installing required dependency '$pkg' ...\n"
	[ -z "${wrksrc}" ] && wrksrc="$XBPS_BUILDDIR/$pkgname"
	[ ! -d "${wrksrc}" ] && mkdir -p "${wrksrc}"
	${cmd} "\"$pkg\"" >${wrksrc}/.xbps_install_dependency_${pkgdepname}.log 2>&1
	rval=$?
	if [ $rval -ne 0 -a $rval -ne 6 -a $rval -ne 2 ]; then
		# EEXIST errors are ignored, handle all any errors here.
		msg_red "'${pkgname}': failed to install '${pkg}' dependency!\n"
		msg_error "Please see ${wrksrc}/.xbps_install_${pkgdepname}.log to see what went wrong!\n"
	elif [ $rval -eq 2 ]; then
		# package not found (ENOENT), try to workaround it if there
		# are extra double quotes.
		${cmd} "$pkg" >${wrksrc}/.xbps_install_dependency_${pkgdepname}.log 2>&1
		if [ $? -ne 0 -a $? -ne 6 -a $? -ne 2 ]; then
			msg_red "'${pkgname}': failed to install '${pkg}' dependency!\n"
			msg_error "Please see ${wrksrc}/.xbps_install_${pkgdepname}.log to see what went wrong!\n"
		fi
	fi

	return $rval
}

autoremove_pkg_dependencies()
{
	local cmd saved_pkgname x f found

	cmd="${fakeroot_cmd} ${fakeroot_cmd_args} ${XBPS_BIN_CMD}"

	# If XBPS_PREFER_BINPKG_DEPS is set, we should remove those
	# package dependencies installed by the target package, do it.
	#
	if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$base_chroot" \
	     -a -z "$INSTALLING_DEPS" ]; then
		msg_normal "'$pkgname': removing automatically installed dependencies ...\n"
		# Autoremove installed binary packages.
		${cmd} -y reconfigure all && ${cmd} -Rpyf autoremove 2>&1 >/dev/null
		if [ $? -ne 0 ]; then
			msg_error "'$pkgname': failed to remove automatic dependencies!\n"
		fi
		# Maybe some dependency wasn't available in repositories and it had
		# to be built from source, remove them too.
		saved_pkgname=$pkgname
		for f in $($XBPS_BIN_CMD list|awk '{print $1}'); do
			pkgname=$($XBPS_PKGDB_CMD getpkgname $f)
			[ "$pkgname" = "$saved_pkgname" ] && continue
			if [ -f $XBPS_PKGMETADIR/$pkgname/flist ]; then
				setup_tmpl $pkgname
				for x in ${subpackages}; do
					if [ "$pkgname" = "$x" ]; then
						found=1
						break;
					fi
				done
				if [ -n "$found" ]; then
					# ignore subpkgs.
					unset found
					continue
				fi
				# remove pkg.
				msg_warn "removing package $pkgname installed from source...\n"
				remove_pkg
			fi
		done
		setup_tmpl $saved_pkgname
	fi
}

#
# Recursive function that installs all direct and indirect
# dependencies of a package.
#
install_pkg_deps()
{
	local curpkg="$1"
	local curpkgname="$(${XBPS_PKGDB_CMD} getpkgdepname $1)"
	local saved_prevpkg="$(${XBPS_PKGDB_CMD} getpkgdepname $2)"
	local j jver jname reqver

	[ -z "$curpkg" -o -z "$curpkgname" ] && return 2

	if [ -n "$prev_pkg" ]; then
		curpkg=$prev_pkg
		curpkgname="$(${XBPS_PKGDB_CMD} getpkgdepname ${curpkg})"
	fi

	check_pkgdep_matched "$curpkg"
	[ $? -eq 0 ] && return 0

	if [ -z "$saved_prevpkg" -a -n "${_ORIGINPKG}" ]; then
		msg_normal "Installing '${_ORIGINPKG}' dependency: '$curpkg'.\n"
	else
		msg_normal "Installing '$saved_prevpkg' dependency: '$curpkg'.\n"
	fi

	setup_tmpl "$curpkgname"
	check_build_depends_pkg
	if [ $? -eq 0 ]; then
		msg_normal "Package dependency '$curpkgname' requires:\n"
		for j in ${build_depends}; do
			jname="$(${XBPS_PKGDB_CMD} getpkgdepname ${j})"
			jver="$($XBPS_PKGDB_CMD version ${jname})"
			check_pkgdep_matched "${j}"
			if [ $? -eq 0 ]; then
				echo "   ${j}: found '$jname-$jver'."
			else
				echo "   ${j}: not found."
			fi
		done
	fi

	for j in ${build_depends}; do
		#
		# Check if dep is satisfied.
		#
		check_pkgdep_matched "${j}"
		[ $? -eq 0 ] && continue

		prev_pkg="$j"
		if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$base_chroot" ]; then
			install_pkg_from_repos ${j}
			if [ $? -eq 255 ]; then
				# xbps-bin returned unexpected error
				msg_red "$saved_prevpkg: failed to install dependency '$j'\n"
			elif [ $? -eq 0 ]; then
				# package installed successfully.
				:
				continue
			fi
		fi
		#
		# Iterate again, this will check if there are more
		# required deps for current pkg.
		#
		install_pkg_deps "${j}" "${curpkg}"
		if [ $? -eq 1 ]; then
			if [ -n "$saved_prevpkg" ]; then
				msg_red "'$saved_prevpkg': failed to install dependency '$curpkg'\n"
			else
				msg_red "'${_ORIGINPKG}': failed to install dependency '$curpkg'\n"
			fi
			return 1
		fi
	done

	if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$base_chroot" ]; then
		install_pkg_from_repos ${curpkg}
		if [ $? -eq 255 ]; then
			# xbps-bin returned unexpected error
			return $?
		elif [ $? -eq 1 ]; then
			# Package not found, build from source.
			install_pkg "${curpkgname}"
			if [ $? -eq 1 ]; then
				msg_red "'$saved_prevpkg': failed to install dependency '$curpkg'\n"
				return 1
			fi
		fi
	else
		if [ -n "$saved_prevpkg" ]; then
			msg_normal "'$saved_prevpkg': installing dependency '$curpkg'...\n"
		else
			msg_normal "'${_ORIGINPKG}': installing dependency '$curpkg'...\n"
		fi
		install_pkg "${curpkgname}"
		if [ $? -eq 1 ]; then
			msg_red "'$saved_prevpkg': failed to install dependency '$curpkg'\n"
			return 1
		fi
	fi
	unset prev_pkg
}

#
# Installs all dependencies required by a package.
#
install_dependencies_pkg()
{
	local pkg="$1" rval
	local lpkgname=$(${XBPS_PKGDB_CMD} getpkgname ${pkg})
	local i j pkgn iver reqver notinstalled_deps lver

	[ -z "$pkg" ] && return 2
	[ -z "$build_depends" ] && return 0

	INSTALLING_DEPS=1

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	msg_normal "'$pkgname-$lver': required build dependencies...\n"

	for i in ${build_depends}; do
		pkgn="$($XBPS_PKGDB_CMD getpkgdepname ${i})"
		iver="$($XBPS_PKGDB_CMD version $pkgn)"
		check_pkgdep_matched "${i}"
		if [ $? -eq 0 ]; then
			echo "   ${i}: found '$pkgn-$iver'."
		else
			echo "   ${i}: not found."
			notinstalled_deps="$notinstalled_deps $i"
		fi
	done

	# Install direct build dependencies from binary packages.
	if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$base_chroot" ]; then
		msg_normal "'$pkg': installing dependencies from repositories ...\n"
		for i in ${notinstalled_deps}; do
			install_pkg_from_repos ${i}
			rval=$?
			if [ $rval -eq 255 ]; then
				# xbps-bin returned unexpected error (-1)
				msg_error "'${lpkgname}': failed to install dependency: '$i'.\n"
			elif [ $rval -eq 0 ]; then
				# Install successfully
				continue
			fi
		done
	fi

	# Install direct and indirect build dependencies from source.
	for j in ${notinstalled_deps}; do
		install_pkg_deps "${j}" "${pkg}"
		if [ $? -eq 1 ]; then
			return 1
		fi
	done
}

#
# Returns 0 if pkgpattern in $1 is matched against current installed
# package, 1 otherwise.
#
check_pkgdep_matched()
{
	local pkg="$1" pkgname iver

	[ -z "$pkg" ] && return 2

	pkgname="$($XBPS_PKGDB_CMD getpkgdepname ${pkg})"
	setup_tmpl $pkgname

	iver="$($XBPS_PKGDB_CMD version $pkgname)"
	if [ -n "$iver" ]; then
		${XBPS_PKGDB_CMD} pkgmatch "${pkgname}-${iver}" "${pkg}"
		[ $? -eq 1 ] && return 0
	fi

	return 1
}

#
# Returns 0 if pkgpattern in $1 is installed and greater than current
# installed package, otherwise 1.
#
check_installed_pkg()
{
	local pkg="$1" pkgname iver

	[ -z "$pkg" ] && return 2

	pkgname="$($XBPS_PKGDB_CMD getpkgname ${pkg})"
	setup_tmpl $pkgname

	iver="$($XBPS_PKGDB_CMD version $pkgname)"
	if [ -n "$iver" ]; then
		${XBPS_CMPVER_CMD} "${pkgname}-${iver}" "${pkg}"
		[ $? -eq 0 -o $? -eq 1 ] && return 0
	fi

	return 1
}

#
# Returns 0 if pkg has build deps, 1 otherwise.
#
check_build_depends_pkg()
{
	[ -z "$pkgname" ] && return 2

	if [ -n "$build_depends" ]; then
		return 0
	else
		return 1
	fi
}
