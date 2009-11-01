#-
# Copyright (c) 2008-2009 Juan Romero Pardines.
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
	local curpkgname=$(${XBPS_PKGDB_CMD} getpkgname $1)
	local saved_prevpkg=$(${XBPS_PKGDB_CMD} getpkgname $2)
	local j jver jname reqver

	[ -z "$curpkg" ] && return 1

	if [ -n "$prev_pkg" ]; then
		curpkg=$prev_pkg
		curpkgname=$(${XBPS_PKGDB_CMD} getpkgname ${curpkg})
	fi

	msg_normal "Installing $saved_prevpkg dependency: $curpkgname."

	run_template $curpkgname
	check_build_depends_pkg
	if [ $? -eq 0 ]; then
		msg_normal "Dependency $curpkgname requires:"
		for j in ${build_depends}; do
			jname=$(${XBPS_PKGDB_CMD} getpkgname ${j})
			jver=$($XBPS_PKGDB_CMD version ${jname})
			reqver=$(${XBPS_PKGDB_CMD} getpkgversion ${j})
                	check_installed_pkg $j
                	if [ $? -eq 0 ]; then
                        	echo "   $jname >= $reqver: found $jname-$jver."
                	else
                        	echo "   $jname >= $reqver: not found."
                	fi
		done
	fi

        for j in ${build_depends}; do
                #
                # Check if dep already installed.
                #
                check_installed_pkg $j
                [ $? -eq 0 ] && continue

                [ -n "$prev_pkg" ] && unset prev_pkg
                #
		# Iterate again, this will check if there are more
		# required deps for current pkg.
                #
                install_pkg_deps $j $curpkg
                prev_pkg="$j"
        done

	install_pkg $curpkgname
	[ -n "$prev_pkg" ] && unset prev_pkg
}

#
# Installs all dependencies required by a package.
#
install_dependencies_pkg()
{
	local pkg="$1"
	local lpkgname=$(${XBPS_PKGDB_CMD} getpkgname ${pkg})
	local i ipkgname ivers reqvers notinstalled_deps lver

	[ -z "$pkg" ] && return 1

	doing_deps=true

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	msg_normal "Required build dependencies for $pkgname-$lver... "
	for i in ${build_depends}; do
                ipkgname=$(${XBPS_PKGDB_CMD} getpkgname ${i})
                ivers=$($XBPS_PKGDB_CMD version $ipkgname)
                reqvers=$(${XBPS_PKGDB_CMD} getpkgversion ${i})
		check_installed_pkg $i
		if [ $? -eq 0 ]; then
			echo "  $ipkgname >= $reqvers: found $ipkgname-$ivers."
			continue
		else
			echo "  $ipkgname >= $reqvers: not found."
			notinstalled_deps="$notinstalled_deps $i"
		fi
	done

	[ -z "$notinstalled_deps" ] && return 0

	for i in ${notinstalled_deps}; do
		check_installed_pkg $i
		[ $? -eq 0 ] && continue

		ipkgname=$(${XBPS_PKGDB_CMD} getpkgname ${i})
		run_template $ipkgname
		check_build_depends_pkg
		if [ $? -eq 1 ]; then
			msg_normal "Installing $lpkgname dependency: $ipkgname."
			install_pkg $ipkgname
		else
			install_pkg_deps $i $pkg
		fi
	done
}

#
# Checks the registered pkgs db file and returns 0 if a pkg that satisfies
# the minimal required version is there, or 1 otherwise.
#
check_installed_pkg()
{
	local pkg="$1"
	local pkgname reqver iver

	[ -z "$pkg" ] && return 2

	pkgname=$(${XBPS_PKGDB_CMD} getpkgname $pkg)
	reqver=$(${XBPS_PKGDB_CMD} getpkgversion $pkg)
	run_template $pkgname

	iver="$($XBPS_PKGDB_CMD version $pkgname)"
	if [ -n "$iver" ]; then
		xbps-cmpver $pkgname-$iver $pkgname-$reqver
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
