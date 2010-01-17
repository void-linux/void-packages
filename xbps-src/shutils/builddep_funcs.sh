#-
# Copyright (c) 2008-2010 Juan Romero Pardines.
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

. $XBPS_SHUTILSDIR/tmpl_funcs.sh

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

	[ -z "$curpkg" ] && return 1

	if [ -n "$prev_pkg" ]; then
		curpkg=$prev_pkg
		curpkgname="$(${XBPS_PKGDB_CMD} getpkgdepname ${curpkg})"
	fi

	msg_normal "Installing $saved_prevpkg dependency: $curpkgname."

	setup_tmpl $curpkgname
	check_build_depends_pkg
	if [ $? -eq 0 ]; then
		msg_normal "Dependency $curpkgname requires:"
		for j in ${build_depends}; do
			jname="$(${XBPS_PKGDB_CMD} getpkgdepname ${j})"
			jver="$($XBPS_PKGDB_CMD version ${jname})"
			check_pkgdep_matched "${j}"
			if [ $? -eq 0 ]; then
				echo "   ${j}: found $jname-$jver."
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

		[ -n "$prev_pkg" ] && unset prev_pkg
		#
		# Iterate again, this will check if there are more
		# required deps for current pkg.
		#
		install_pkg_deps $j $curpkg
		prev_pkg="$j"
	done

	if [ -n "$XBPS_PREFER_BINPKG_DEPS" ]; then
		install_pkg_with_binpkg ${curpkg}
		if [ $? -eq 255 ]; then
			# xbps-bin returned unexpected error
			return $?
		elif [ $? -eq 1 ]; then
			# Package not found, build from source.
			install_pkg $curpkgname
		fi
	else
		install_pkg $curpkgname
	fi
	[ -n "$prev_pkg" ] && unset prev_pkg
}

#
# Installs all dependencies required by a package.
#
install_dependencies_pkg()
{
	local pkg="$1"
	local lpkgname=$(${XBPS_PKGDB_CMD} getpkgname ${pkg})
	local i pkgn iver reqver notinstalled_deps lver

	[ -z "$pkg" ] && return 1

	doing_deps=true

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	if [ -n "$build_depends" -o -n "$run_depends" ]; then
		msg_normal "Required dependencies for $pkgname-$lver... "
	fi
	for i in ${build_depends}; do
		pkgn="$($XBPS_PKGDB_CMD getpkgdepname ${i})"
		iver="$($XBPS_PKGDB_CMD version $pkgn)"
		check_pkgdep_matched "${i}"
		if [ $? -eq 0 ]; then
			echo "  ${i}: found $pkgn-$iver."
			continue
		else
			echo "  ${i}: not found."
			notinstalled_deps="$notinstalled_deps $i"
		fi
	done

	[ -z "$notinstalled_deps" ] && return 0

	for i in ${notinstalled_deps}; do
		if [ -n "$XBPS_PREFER_BINPKG_DEPS" ]; then
			install_pkg_with_binpkg ${i}
			if [ $? -eq 255 ]; then
				# xbps-bin returned unexpected error (-1)
				return $?
			elif [ $? -eq 0 ]; then
				# installed successfully
				continue
			fi
		fi
		pkgn=$($XBPS_PKGDB_CMD getpkgdepname ${i})
		check_pkgdep_matched "${i}"
		[ $? -eq 0 ] && continue

		setup_tmpl $pkgn
		check_build_depends_pkg
		if [ $? -eq 1 ]; then
			msg_normal "Installing $lpkgname dependency: $pkgn."
			if [ -n "$XBPS_PREFER_BINPKG_DEPS" ]; then
				install_pkg_with_binpkg ${i}
				if [ $? -eq 255 ]; then
					# xbps-bin returned unexpected error
					return $?
				elif [ $? -eq 0 ]; then
					# installed successfully
					continue
				else
					# package not found, build source.
					install_pkg $pkgn
				fi
			else
				install_pkg $pkgn
			fi
		else
			install_pkg_deps "${i}" $pkg
		fi
	done
}

#
# Checks if installed pkg dependency is matched against pattern.
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
# Check if installed package is installed.
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
# Checks the build depends db file and returns 0 if pkg has dependencies,
# otherwise returns 1.
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
