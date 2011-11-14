#-
# Copyright (c) 2010-2011 Juan Romero Pardines.
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
	local j f nlib verify_deps maplib found_dup igndir soname_arch
	local broken rdep found rsonamef soname_list revbumped tmplf newrev

	maplib="$XBPS_COMMONVARSDIR/mapping_shlib_binpkg.txt"

	[ -n "$noarch" -o -n "$noverifyrdeps" ] && return 0
	msg_normal "$pkgver: verifying required shlibs...\n"

	depsftmp=$(mktemp -t xbps_src_depstmp.XXXXXXXXXX) || exit 1
	find ${1} -type f -perm -u+w > $depsftmp 2>/dev/null

	exec 3<&0 # save stdin
	exec < $depsftmp
	while read f; do
		# Don't check dirs specified in ignore_vdeps_dir.
		for j in ${ignore_vdeps_dir}; do
			if grep -q ${j} "${f}"; then
				igndir=1
				break
			fi
		done
		[ -n "$igndir" ] && continue
		unset igndir

		case "$(file -bi "$f")" in
		application/x-executable*|application/x-sharedlib*)
			for nlib in $(objdump -p "$f"|grep NEEDED|awk '{print $2}'); do
				if [ -z "$verify_deps" ]; then
					verify_deps="$nlib"
					continue
				fi
				for j in ${verify_deps}; do
					[ "$j" != "$nlib" ] && continue
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
	exec 0<&3 # restore stdin
	rm -f $depsftmp

	if [ -f $XBPS_SRCPKGDIR/$pkgname/$pkgname.template ]; then
		tmplf=$XBPS_SRCPKGDIR/$pkgname/$pkgname.template
	else
		tmplf=$XBPS_SRCPKGDIR/$pkgname/template
	fi
	#
	# Add required run time packages by using required shlibs resolved
	# above, the mapping is done thru the mapping_shlib_binpkg.txt file.
	#
	for f in ${verify_deps}; do
		# Bail out if maplib is not aware for this lib
		rdep="$(grep "$f" $maplib|awk '{print $2}')"
		rdepcnt="$(grep "$f" $maplib|awk '{print $2}'|wc -l)"
		if [ -z "$rdep" ]; then
			echo "   SONAME: $f <-> UNKNOWN PKG PLEASE FIX!"
			broken=1
		fi
		# Check if shlib is provided by multiple pkgs.
		if [ "$rdepcnt" -gt 1 ]; then
			for j in ${rdep}; do
				[ -z "${_rdep}" ] && _rdep=$j
			done
		else
			_rdep=$rdep
		fi
		# Ignore libs by current pkg
		if [ "${_rdep}" = "$pkgname" ]; then
			echo "   SONAME: $f <-> ${_rdep} (ignored)"
			continue
		fi

		# Add required shlib to rundeps.
		echo "   SONAME: $f <-> ${_rdep}"
		if [ -z "$soname_list" ]; then
			soname_list="${f}"
		else
			soname_list="${soname_list} ${f}"
		fi
		# Try to remove the line from template
		sed -i -r "/^Add_dependency run ${_rdep}([[:space:]]+\".*\")*$/d" $tmplf
		if find_rundep ${_rdep}; then
			Add_dependency run ${_rdep}
		fi
		unset rdep _rdep rdepcnt
	done
	#
	# If pkg uses any SONAME not known, error out.
	#
	[ -n "$broken" ] && \
		msg_error "$pkgver: cannot guess required shlibs, aborting!\n"

	#
	# Update package's rshlibs file.
	#
	unset broken
	msg_normal "$pkgver: updating rshlibs file...\n"
	rsonamef=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.rshlibs
	if [ ! -f $rsonamef ]; then
		# file not found, add soname.
		for j in ${soname_list}; do
			echo "   SONAME: $j (added)"
			echo "${j}" >> $rsonamef
		done
		[ -n "$soname_list" ] && broken=1
	else
		# check if soname is already in the rshlibs file.
		for j in ${soname_list}; do
			if ! grep -q "$j" $rsonamef; then
				echo "   SONAME: $j (added)"
				echo "$j" >> $rsonamef
				broken=1
			fi
		done
		exec 3<&0 # save stdin
		exec < $rsonamef
		# now check if any soname in the rshlibs file is unnecessary.
		while read f; do
			for j in ${soname_list}; do
				if [ "$f" = "$j" ]; then
					found=1
					continue
				fi
			done
			if [ -n "$found" ]; then
				unset found
				continue
			fi
			# If SONAME is arch specific, only remove it if
			# matching on the target arch.
			soname_arch=$(grep "$f" $maplib|awk '{print $4}')
			if [ -z "$soname_arch" ] || \
			   [ -n "$soname_arch" -a "$soname_arch" = "$XBPS_MACHINE" ]; then
				echo "   SONAME: $f (removed, not required)"
				sed -i "/^${f}$/d" $rsonamef
				broken=1
			fi
		done
		exec 0<&3 # restore stdin
	fi

	if [ -n "$broken" ]; then
		msg_warn "$pkgver: shlibs changed... package has been revbumped!\n"
		_rev=$(egrep '^revision=.*' $tmplf)
		if [ -n "${_rev}" ]; then
			if [ -z "$revbumped" ]; then
				readonly newrev=$((${_rev#revision=} + 1))
				sed -i "s/^revision=.*$/revision=${newrev}/" $tmplf
				export revision=${newrev}
				export pkgver="${pkgname}-${version}_${revision}"
				revbumped=1
			fi
		else
			if [ -z "$revbumped" ]; then
				sed -i "/^short_desc=.*$/irevision=1" $tmplf
				export revision=1
				export pkgver="${pkgname}-${version}_${revision}"
				revbumped=1
			fi
		fi
	fi
}
