#-
# Copyright (c) 2008 Juan Romero Pardines.
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
# Recursive function that founds dependencies in all required
# packages.
#
add_dependency_tolist()
{
	local curpkg="$1"
	local j=

	[ -z "$curpkg" ] && return 1
	[ -n "$prev_pkg" ] && curpkg=$prev_pkg

	if [ "$pkgname" != "${curpkg%-[0-9]*.*}" ]; then
		reset_tmpl_vars
		. $XBPS_TEMPLATESDIR/${curpkg%-[0-9]*.*}.tmpl
	fi

	for j in ${build_depends}; do
		#
		# Check if dep already installed.
		#
		check_installed_pkg $j ${j##[aA-zZ]*-}
		#
		# If dep is already installed, check one more time
		# if all its deps are there and continue.
		#
		if [ $? -eq 0 ]; then
			install_builddeps_required_pkg $j
			installed_deps_list="$j $installed_deps_list"
			continue
		fi

		deps_list="$j $deps_list"
		[ -n "$prev_pkg" ] && unset prev_pkg
		#
		# Check if dependency needs more deps.
		#
		check_build_depends_pkg ${j%-[0-9]*.*}
		if [ $? -eq 0 ]; then
			add_dependency_tolist $j
			prev_pkg="$j"
		fi
	done
}

#
# Removes duplicate deps in the installed or not installed list.
#
find_dupdeps_inlist()
{
	local action="$1"
	local tmp_list=
	local dup=
	local f=

	[ -z "$action" ] && return 1

	case "$action" in
	installed)
		list=$installed_deps_list
		;;
	notinstalled)
		list=$deps_list
		;;
	*)
		return 1
		;;
	esac

	for f in $list; do
		if [ -z "$tmp_list" ]; then
			tmp_list="$f"
		else
			for i in $tmp_list; do
				[ "$f" = "$i" ] && dup=yes
			done

			[ -z "$dup" ] && tmp_list="$tmp_list $f"
			unset dup
		fi
	done

	case "$action" in
	installed)
		installed_deps_list="$tmp_list"
		;;
	notinstalled)
		deps_list="$tmp_list"
		;;
	*)
		return 1
		;;
	esac
}

#
# Installs all dependencies required by a package.
#
install_dependencies_pkg()
{
	local pkg="$1"
	local i=
	local ipkg=
	local iversion=
	deps_list=
	installed_deps_list=

	[ -z "$pkg" ] && return 1

	doing_deps=true

	echo "==> Calculating dependency list for $pkgname-$version... "
	add_dependency_tolist $pkg
	find_dupdeps_inlist installed
	find_dupdeps_inlist notinstalled

	[ -z "$deps_list" -a -z "$installed_deps_list" ] && return 0

	msg_normal "Required minimal deps for $(basename $pkg):"
	for i in ${installed_deps_list}; do
		ipkg=${i%-[0-9]*.*}
		iversion="$($XBPS_REGPKGDB_CMD version $ipkg)"
		echo "	$ipkg >= ${i##[aA-zZ]*-}: found $ipkg-$iversion."
	done

	for i in ${deps_list}; do
		echo "	${i%-[0-9]*.*} >= ${i##[aA-zZ]*-}: not found."
	done

	for i in ${deps_list}; do
		# skip dup deps
		check_installed_pkg $i ${i##[aA-zZ]*-}
		[ $? -eq 0 ] && continue
		# continue installing deps
		msg_normal "Installing $pkg dependency: $i."
		install_pkg ${i%-[0-9]*.*}
	done

	unset installed_deps_list
	unset deps_list
}

install_builddeps_required_pkg()
{
	local pkg="$1"
	local dep=

	[ -z "$pkg" ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		. $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	for dep in ${build_depends}; do
		check_installed_pkg $dep ${dep##[aA-zZ]*-}
		if [ $? -ne 0 ]; then
			msg_normal "Installing $pkg dependency: $dep."
			install_pkg ${dep%-[0-9]*.*}
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
	local reqver="$2"
	local iver=

	[ -z "$pkg" -o -z "$reqver" -o ! -r $XBPS_REGPKGDB_PATH ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		reset_tmpl_vars
		. $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	iver="$($XBPS_REGPKGDB_CMD version $pkgname)"
	if [ -n "$iver" ]; then
		xbps-cmpver $pkgname-$iver $pkgname-$reqver
		[ $? -eq 0 ] && return 0
	fi

	return 1
}

#
# Checks the build depends db file and returns 0 if pkg has dependencies,
# otherwise returns 1.
#
check_build_depends_pkg()
{
	local pkg="$1"

	[ -z $pkg ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		reset_tmpl_vars
		. $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	if [ -n "$build_depends" ]; then
		return 0
	else
		return 1
	fi
}
