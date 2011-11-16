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

#
# Install a required package dependency, like:
#
#	xbps-bin -Ay install "pattern"
#
install_pkg_from_repos()
{
	local rval tmplogf tmpdepf

	msg_normal "$pkgver: installing '$1'... "

	case "${XBPS_VERSION}" in
	0.1[1-9].[0-9]*)
		_pkgdepname=$($XBPS_PKGDB_CMD getpkgdepname "$1")
		$XBPS_REPO_CMD -oversion show ${_pkgdepname} >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			msg_normal_append "not found, building from source...\n"
			return 2
		fi
		_pkgver=$($XBPS_REPO_CMD} -oversion show ${_pkgdepname})
		msg_normal_append "found ${_pkgver} "
		$XBPS_PKGDB_CMD pkgmatch "${_pkgdepname}-${_pkgver}" "${1}"
		if [ $? -eq 1 ]; then
			_repoloc=$($XBPS_REPO_CMD} -orepository show ${_pkgdepname})
			msg_normal_append "(${_repoloc})\n"
		else
			msg_normal_append "not matched, building from source...\n"
			return 2
		fi
		;;
	*)	msg_normal_append "\n";;
	esac

	tmplogf=$(mktemp)
	$FAKEROOT_CMD $FAKEROOT_CMD_ARGS $XBPS_BIN_CMD -Ay install ${_pkgdepname} >$tmplogf 2>&1
	rval=$?
	if [ $rval -ne 0 -a $rval -ne 6 ]; then
		# xbps-bin can return:
		#
		#	SUCCESS (0): package installed successfully.
		#	ENOENT  (2): package missing in repositories.
		#	EEXIST  (6): package already installed.
		#	ENODEV (19): package depends on missing dependencies.
		#
		# Any other error returned is critical.
		autoremove_pkg_dependencies $KEEP_AUTODEPS
		msg_red "$pkgver: failed to install '$1' dependency! (error $rval)\n"
		cat $tmplogf && rm -f $tmplogf
		msg_error "Please see above for the real error, exiting...\n"
	fi
	rm -f $tmplogf

	return $rval
}

autoremove_pkg_dependencies()
{
	local cmd curpkgname f

	[ -n "$1" ] && return 0

	cmd="${FAKEROOT_CMD} ${FAKEROOT_CMD_ARGS} ${XBPS_BIN_CMD}"

	# If XBPS_PREFER_BINPKG_DEPS is set, we should remove those
	# package dependencies installed by the target package, do it.
	#
	if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$bootstrap" ]; then
		msg_normal "$pkgver: removing automatically installed dependencies ...\n"
		# Autoremove installed binary packages.
		${cmd} -y reconfigure all && ${cmd} -Rpyf autoremove
		if [ $? -ne 0 ]; then
			msg_red "$pkgver: failed to remove automatic dependencies!\n"
			exit 1
		fi
	fi
}

#
# Recursive function that installs all direct and indirect
# dependencies of a package.
#
install_pkg_deps()
{
	local curpkg="$1"
	local curpkgname=$(${XBPS_PKGDB_CMD} getpkgdepname "$1")
	local saved_prevpkg=$(${XBPS_PKGDB_CMD} getpkgdepname "$2")
	local j jver jname reqver

	[ -z "$curpkg" -o -z "$curpkgname" ] && return 2

	if [ -n "$prev_pkg" ]; then
		curpkg=$prev_pkg
		curpkgname="$(${XBPS_PKGDB_CMD} getpkgdepname ${curpkg})"
	fi

	check_pkgdep_matched "$curpkg"
	[ $? -eq 0 ] && return 0

	if [ -z "$saved_prevpkg" -a -n "${_ORIGINPKG}" ]; then
		msg_normal "Installing ${_ORIGINPKG} dependency: '$curpkg'.\n"
	else
		msg_normal "Installing $saved_prevpkg dependency: '$curpkg'.\n"
	fi

	setup_tmpl "$curpkgname"
	check_build_depends_pkg
	if [ $? -eq 0 ]; then
		msg_normal "Package '$curpkgname' requires:\n"
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
		prev_pkg="$j"
		if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$bootstrap" ]; then
			install_pkg_from_repos "${j}"
			if [ $? -eq 255 ]; then
				# xbps-bin returned unexpected error
				msg_red "$saved_prevpkg: failed to install '$j'\n"
			elif [ $? -eq 0 ]; then
				# package installed successfully.
				:
				continue
			fi
		else
			#
			# Iterate again, this will check if there are more
			# required deps for current pkg.
			#
			install_pkg_deps "${j}" "${curpkg}"
			if [ $? -eq 1 ]; then
				if [ -n "$saved_prevpkg" ]; then
					msg_red "$saved_prevpkg: failed to install '$curpkg'\n"
				else
					msg_red "${_ORIGINPKG}: failed to install '$curpkg'\n"
				fi
				return 1
			fi
		fi
	done

	if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$bootstrap" ]; then
		install_pkg_from_repos "${curpkg}"
		if [ $? -eq 255 ]; then
			# xbps-bin returned unexpected error
			return $?
		elif [ $? -eq 2 ]; then
			# Package not found, build from source.
			install_pkg "${curpkgname}"
			if [ $? -eq 1 ]; then
				msg_red "$saved_prevpkg: failed to install '$curpkg'\n"
				return 1
			fi
		fi
	else
		if [ -n "$saved_prevpkg" ]; then
			msg_normal "$saved_prevpkg: installing '$curpkg'...\n"
		else
			msg_normal "${_ORIGINPKG}: installing '$curpkg'...\n"
		fi
		install_pkg "${curpkgname}"
		if [ $? -eq 1 ]; then
			msg_red "$saved_prevpkg: failed to install '$curpkg'\n"
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
	local pkg="$1"
	local i pkgn iver missing_deps
	trap "msg_error 'interrupted\n'" INT

	[ -z "$pkg" ] && return 2
	[ -z "$build_depends" ] && return 0

	INSTALLING_DEPS=1

	msg_normal "$pkgver: required build dependencies...\n"

	for i in ${build_depends}; do
		pkgn=$($XBPS_PKGDB_CMD getpkgdepname "${i}")
		iver=$($XBPS_PKGDB_CMD version "${pkgn}")
		check_pkgdep_matched "${i}"
		if [ $? -eq 0 ]; then
			echo "   ${i}: found '$pkgn-$iver'."
		else
			echo "   ${i}: not found."
			if [ -z "$missing_deps" ]; then
				missing_deps="${i}"
			else
				missing_deps="${missing_deps} ${i}"
			fi
		fi
	done

	[ -z "$missing_deps" ] && return 0

	# Install direct build dependencies from binary packages.
	if [ -n "$XBPS_PREFER_BINPKG_DEPS" -a -z "$bootstrap" ]; then
		msg_normal "$pkgver: installing dependencies from repositories ...\n"
		for i in ${missing_deps}; do
			install_pkg_from_repos "${i}"
			if [ $? -eq 2 ]; then
				# ENOENT; install from source
				install_pkg_deps "${i}" "${pkg}" || return 1
				curpkgdepname="$($XBPS_PKGDB_CMD getpkgdepname ${i})"
				setup_tmpl $curpkgdepname
				install_pkg $curpkgdepname
				setup_tmpl $($XBPS_PKGDB_CMD getpkgname ${pkg})
				install_dependencies_pkg "${pkg}"
			fi
		done
	else
		# Install direct and indirect build dependencies from source.
		for i in ${missing_deps}; do
			install_pkg_deps "${i}" "${pkg}" || return 1
		done
	fi

	# unregister sighandler.
	trap - INT
}

#
# Returns 0 if pkgpattern in $1 is matched against current installed
# package, 1 otherwise.
#
check_pkgdep_matched()
{
	local pkg="$1" pkgn iver

	[ -z "$pkg" ] && return 2

	pkgn="$($XBPS_PKGDB_CMD getpkgdepname ${pkg})"
	[ -z "$pkgn" ] && return 2

	iver="$($XBPS_PKGDB_CMD version $pkgn)"
	if [ -n "$iver" ]; then
		${XBPS_PKGDB_CMD} pkgmatch "${pkgn}-${iver}" "${pkg}"
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
	local pkg="$1" pkgn iver

	[ -z "$pkg" ] && return 2

	pkgn="$($XBPS_PKGDB_CMD getpkgname ${pkg})"
	[ -z "$pkgn" ] && return 2

	iver="$($XBPS_PKGDB_CMD version $pkgn)"
	if [ -n "$iver" ]; then
		${XBPS_CMPVER_CMD} "${pkgn}-${iver}" "${pkg}"
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
