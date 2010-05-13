#!/bin/sh
#-
# Copyright (c) 2010 Juan Romero Pardines.
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
# Finds all required libraries for a package, by looking at its executables
# and shared libraries and skipping duplicated matches.
#
# Once the list is known it finds the binary package names mapped to those
# libraries and reports if any of them was not added.
#

find_rundep()
{
	local dep="$1" i rpkgdep

	for i in ${run_depends}; do
		rpkgdep="$($XBPS_PKGDB_CMD getpkgdepname $i)"
		[ "${rpkgdep}" != "${dep}" ] && continue
		return 1
	done
}

verify_rundeps()
{
	local j i f nlib verify_deps maplib found_dup igndir lver
	local missing missing_libs rdep builddep rdep_list builddep_list

	PKG_DESTDIR="$1"
	maplib="$XBPS_COMMONVARSDIR/mapping_shlib_binpkg.txt"

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	[ -n "$noarch" -o "$nostrip" -o "$noverifyrdeps" ] && return 0
	msg_normal "Package '$pkgname ($lver)': verifying required run dependencies, please wait..."

	for f in $(find ${PKG_DESTDIR} -type f); do
		# Don't check dirs specified in ignore_vdeps_dir.
		for j in ${ignore_vdeps_dir}; do
			if grep -q ${j} ${f}; then
				igndir=1
				break
			fi
		done
		[ -n "$igndir" ] && continue
		unset igndir

		case "$(file -biz $f)" in
		application/x-executable*|application/x-sharedlib*)
			for nlib in $(objdump -p $f|grep NEEDED|awk '{print $2}'); do
				# Strip major version
				nlib="$(echo $nlib|sed -e 's|\.[0-9]$||')"
				if [ -z "$verify_deps" ]; then
					verify_deps="$nlib"
					continue
				fi
				for i in ${verify_deps}; do
					[ "$i" != "$nlib" ] && continue
					found_dup=1
					break
				done
				if [ -z "$found_dup" ]; then
					verify_deps="$verify_deps $nlib"
				fi
				unset found_dup
			done
			;;
		esac
	done

	# Now verify that those required libs are added into package's
	# template via Add_dependency.
	for f in ${verify_deps}; do
		# Bail out if maplib is not aware for this lib
		rdep="$(grep "$f" $maplib|awk '{print $2}')"
		rdepcnt="$(grep "$f" $maplib|awk '{print $2}'|wc -l)"
		if [ -z "$rdep" ]; then
			echo "   UNKNOWN PACKAGE FOR SHLIB DEPENDENCY '$f', PLEASE FIX!"
		fi
		# Ignore libs by current pkg
		[ "$rdep" = "$pkgname" ] && continue

		# Check if shlib is provided by multiple pkgs.
		if [ "$rdepcnt" -gt 1 ]; then
			echo "   shlib dependency '$f' is provided by these pkgs: "
			for j in ${rdep}; do
				printf "\t$j\n"
			done
			continue
		fi
		# Warn if rundep is not in template.
		if find_rundep "$rdep"; then
			echo "   REQUIRED SHLIB DEPENDENCY '$f' FROM PACKAGE '$rdep' MISSING, PLEASE FIX!"
			missing=1
			if [ -z "$missing_libs" ]; then
				missing_libs="$f"
				continue
			fi
			for i in ${missing_libs}; do
				[ "$i" != "$f" ] && continue
				found_dup=1
				break
			done
			if [ -z "$found_dup" ]; then
				missing_libs="$missing_libs $f"
			fi
			unset found_dup
			continue
		fi
		echo "   shlib dependency '$f' provided by the '$rdep' package (OK)."
		unset rdep
	done

	[ -z "$missing" ] && return 0

	# Print an informative message suggesting what needs to be added
	# into the build template.

	msg_normal "The following code needs to be added into the build template:"
	echo "============ CUT HERE ==============="

	for f in ${missing_libs}; do
		rdep="$(grep "$f" $maplib|awk '{print $2}')"
		rdepcnt="$(grep "$f" $maplib|awk '{print $2}'|wc -l)"
		builddep="$(grep "$f" $maplib|awk '{print $3}')"

		# If required shlib is provided by multiple pkgs pass
		# to next one.
		[ "$rdepcnt" -gt 1 ] && continue

		if [ -z "$rdep_list" ]; then
			rdep_list="$rdep"
		fi
		if [ -z "$builddep_list" -a -n "$builddep" ]; then
			builddep_list="$builddep"
		fi
		for i in ${rdep_list}; do
			[ "$rdep" != "$i" ] && continue
			found_dup=1
			break
		done
		if [ -z "$found_dup" ]; then
			rdep_list="$rdep_list $rdep"
		fi
		unset found_dup
		for i in ${builddep_list}; do
			[ "$builddep" != "$i" ] && continue
			found_dup=1
			break
		done
		if [ -z "$found_dup" ]; then
			builddep_list="$builddep_list $builddep"
		fi
		unset found_dup
	done

	for f in ${rdep_list}; do
		echo "Add_dependency run $f"
	done
	for f in ${builddep_list}; do
		echo "Add_dependency build $f"
	done
	echo "============ CUT HERE ==============="
}
