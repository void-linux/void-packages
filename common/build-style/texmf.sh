do_build() {
	local f p
	# Extract the source files
	mkdir -p "build/usr/share/texmf-dist"
	find . -maxdepth 1 -print -name "*.tar.xz" \
		-exec bsdtar \
		-s '|^texmf-dist/||' \
		-C "build/usr/share/texmf-dist" \
		-xf {} \;
	cd "build/usr/share/texmf-dist/"
	# LICENSEs are unneeded
	rm -f LICENSE*

	# We have some conflicting files between different packages. To work
	# around this, we use an ownership file that maps which conflicting
	# files should be in which packages. Here, each file in the map list is
	# checked whether it is in the package, and if it shouldn't be it is
	# removed.
	while IFS=' ' read -r f p ; do
		if [ "$p" = "$pkgname" ] && ! [ -e "$f" ]; then
			# Error out if the ownership map expects this package to have a
			# file but it dosen't
			msg_error "$pkgver: missing file $f\n"
		elif [ "$p" != "$pkgname" ] && [ -e "$f" ]; then
			# Remove a file that according to the ownership map belongs to
			# another file
			echo "removed $f"
			# Install a file that lists the removed packages
			mkdir -p ../texlive/removed
			echo "$f" >> ../texlive/removed/$pkgname.txt
			rm -f "$f"
		fi
	done < "${XBPS_COMMONDIR}/environment/build-style/texmf/ownership.txt"
}

do_check() {
	# This is essentially a helper for generating the ownership map. It checks
	# to see if there are any conflicts between all of the different packages.
	local f p current_ver current_rev exitcode=0
	cd build

	while read p; do
		# Don't check against the texlive-bin* packages, ourselves, -dbg or -32bit pkgs
		if [[ ${p%-*} =~ .*-bin$ ]] || [ "${p%-*}" = "$pkgname" ] || [[ ${p%-*} =~ .*-dbg$ ]] || [[ ${p%-*} =~ .*-32bit$ ]]; then
			continue
		fi
		# Don't check against any version other than the version in the source tree
		current_ver="$(grep -m 1 version= ${XBPS_SRCPKGDIR}/${p%-*}/template | cut -d= -f2)"
		current_rev="$(grep -m 1 revision= ${XBPS_SRCPKGDIR}/${p%-*}/template | cut -d= -f2)"
		if [ "${p%-*}-${current_ver}_${current_rev}" != "${p}" ]; then
			# They are not the same version
			continue
		fi
		echo checking conflicts with ${p}...
		while IFS= read -r f; do
			if [ -e ".$f" ]; then
				msg_red "both contain file $f\n"
				exitcode=1
			fi
		done < <(xbps-query -Rf $p | sed 's/ -> .*//')
	done < <(xbps-query -Rs texlive -p pkgver | cut -d : -f 1)
	return $exitcode
}

do_install() {
	vcopy build/usr .
}
