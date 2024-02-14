# scans binpkgs for packages that don't match the current version and removes them.

purge_binpkgs() {
	local max cur percent pnew dir rdata arch template pkg ver rev
	local binpkg pkgfile pkgver pkgname version repos
	local -a binpkg_dirs templates binpkgs
	local -A versions

	if [ -z "$XBPS_REPOSITORY" ]; then
		msg_error "The variable \$XBPS_REPOSITORY is not set."
		exit 1
	fi

	# Scan all templates for their current versions
	mapfile -t templates < <(find srcpkgs -mindepth 1 -maxdepth 1 -type d -printf "srcpkgs/%f/template\n")
	max="${#templates[@]}"
	cur=0
	if [ -z "$max" ]; then
		msg_error "No srcpkgs/*/template files found. Wrong working directory?"
		exit 1
	fi
	percent=-1
	for template in "${templates[@]}"; do
		pkg="${template#*/}"
		pkg="${pkg%/*}"
		if [ ! -L "srcpkgs/$pkg" ]; then
			ver="$(grep -Eh "^version=.*$" "${template}")"
			rev="$(grep -Eh "^revision=.*$" "${template}")"
			versions["$pkg"]="${ver#*=}_${rev#*=}"
		fi
		cur=$((cur + 1))
		pnew=$((100 * cur / max))
		if [ $pnew -ne $percent ]; then
			percent="$pnew"
			printf "\rScanning templates: %3d%% (%d/%d)" "$percent" "$cur" "$max"
		fi
	done
	echo

	binpkgs=("$XBPS_REPOSITORY"/**/*.xbps)
	max=${#binpkgs[@]}
	if [ -z "$max" ]; then
		msg_error "No binpkgs found in '$XBPS_REPOSITORY'"
		exit 1
	fi
	cur=0
	for binpkg in "${binpkgs[@]}"; do
		pkgfile="${binpkg##*/}"
		pkgver="${pkgfile%.*.*}"
		pkgname="$(find -P srcpkgs -maxdepth 2 -samefile "srcpkgs/${pkgver%-*}/template" 2>/dev/null | cut -d/ -f2)"
		[ -z "$pkgname" ] && pkgname="${pkgver%-*}"
		version="${pkgver##*-}"
		# existing package
		if [ -n "${versions[$pkgname]}" ]; then
			# remove if not matching the template version
			if ! xbps-uhelper cmpver "${versions[$pkgname]}" "$version"; then
				rm -vf "$binpkg"
				cur=$((cur + 1))
			fi
		else
			# nonexistant package, remove
			rm -vf "$binpkg"
			cur=$((cur + 1))
		fi
	done

	mapfile -t binpkg_dirs < <(find "$XBPS_REPOSITORY" -type d)
	repos=0
	for dir in "${binpkg_dirs[@]}"; do
		for rdata in "$dir"/*-repodata; do
			arch="${rdata##*/}"
			arch="${arch%-repodata}"
			XBPS_TARGET_ARCH="${arch}" xbps-rindex -c "$dir"
			repos=$((repos + 1))
		done
	done
	echo "Cleaned $cur/$max binpkgs in $XBPS_REPOSITORY"
	echo "Cleaned $repos repositories in $XBPS_REPOSITORY"
	echo "Done."
}
