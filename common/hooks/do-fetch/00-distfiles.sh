# This hook downloads the distfiles specified in a template by
# the $distfiles variable and then verifies its sha256 checksum comparing
# its value with the one stored in the $checksum variable.

# Return the checksum of the contents of a tarball
contents_cksum() {
	local curfile="$1" cursufx cksum

	case $curfile in
	*.tar.lzma)   cursufx="txz";;
	*.tar.lz)     cursufx="tlz";;
	*.tlz)        cursufx="tlz";;
	*.tar.xz)     cursufx="txz";;
	*.txz)        cursufx="txz";;
	*.tar.bz2)    cursufx="tbz";;
	*.tbz)        cursufx="tbz";;
	*.tar.gz)     cursufx="tgz";;
	*.tgz)        cursufx="tgz";;
	*.gz)         cursufx="gz";;
	*.bz2)        cursufx="bz2";;
	*.tar)        cursufx="tar";;
	*.zip)        cursufx="zip";;
	*.rpm)        cursufx="rpm";;
	*.patch)      cursufx="txt";;
	*.diff)       cursufx="txt";;
	*.txt)        cursufx="txt";;
	*.7z)	      cursufx="7z";;
	*.gem)	      cursufx="gem";;
	*.crate)      cursufx="crate";;
	*) msg_error "$pkgver: unknown distfile suffix for $curfile.\n";;
	esac

	case ${cursufx} in
	tar|txz|tbz|tlz|tgz|crate)
		cksum=$($XBPS_DIGEST_CMD <($TAR_CMD -x -O -f "$curfile"))
		if [ $? -ne 0 ]; then
			msg_error "$pkgver: extracting $curfile to pipe.\n"
		fi
		;;
	gz)
		cksum=$($XBPS_DIGEST_CMD <(gunzip -c "$curfile"))
		;;
	bz2)
		cksum=$($XBPS_DIGEST_CMD <(bunzip2 -c "$curfile"))
		;;
	zip)
		if command -v unzip &>/dev/null; then
			cksum=$($XBPS_DIGEST_CMD <(unzip -p "$curfile"))
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile to pipe.\n"
			fi
		else
			msg_error "$pkgver: cannot find unzip bin for extraction.\n"
		fi
		;;
	rpm)
		msg_error "$pkgver: contents checksum not support for rpm.\n"
		;;
	txt)
		cksum=$($XBPS_DIGEST_CMD "$curfile")
		;;
	7z)
		if command -v 7z &>/dev/null; then
			cksum=$($XBPS_DIGEST_CMD <(7z x -o "$curfile"))
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile to pipe.\n"
			fi
		else
			msg_error "$pkgver: cannot find 7z bin for extraction.\n"
		fi
		;;
	gem)
		cksum=$($XBPS_DIGEST_CMD <($TAR_CMD -x -O -f "$curfile" data.tar.gz | $TAR_CMD -xzO ))
		;;
	*)
		msg_error "$pkgver: cannot guess $curfile extract suffix. ($cursufx)\n"
		;;
	esac

	if [ -z "$cksum" ]; then
		msg_error "$pkgver: cannot find contents checksum for $curfile.\n"
	fi
	echo "$cksum"
}

# Verify the checksum for $curfile stored at $distfile and index $dfcount
verify_cksum() {
	local curfile="$1" distfile="$2" cksum="$3" filesum

	# If the checksum starts with an commercial at (@) it is the contents checksum
	if [ "${cksum:0:1}" = "@" ]; then
		cksum=${cksum:1}
		msg_normal "$pkgver: verifying contents checksum for distfile '$curfile'... "
		filesum=$(contents_cksum "$curfile")
		if [ "${cksum}" != "$filesum" ]; then
			echo
			msg_red "SHA256 mismatch for '${curfile}:'\n@${filesum}\n"
			errors=$((errors + 1))
		else
			msg_normal_append "OK.\n"
		fi
	else
		msg_normal "$pkgver: verifying checksum for distfile '$curfile'... "
		filesum=$(${XBPS_DIGEST_CMD} "$distfile")
		if [ "$cksum" != "$filesum" ]; then
			echo
			msg_red "SHA256 mismatch for '${curfile}:'\n${filesum}\n"
			errors=$((errors + 1))
		else
			if [ ! -f "$XBPS_SRCDISTDIR/by_sha256/${cksum}_${curfile}" ]; then
				mkdir -p "$XBPS_SRCDISTDIR/by_sha256"
				ln -f "$distfile" "$XBPS_SRCDISTDIR/by_sha256/${cksum}_${curfile}"
			fi
			msg_normal_append "OK.\n"
		fi
	fi
}

# Link an existing cksum $distfile for $curfile at index $dfcount
link_cksum() {
	local curfile="$1" distfile="$2" cksum="$3"
	if [ -n "$cksum" -a -f "$XBPS_SRCDISTDIR/by_sha256/${cksum}_${curfile}" ]; then
		ln -f "$XBPS_SRCDISTDIR/by_sha256/${cksum}_${curfile}" "$distfile"
		msg_normal "$pkgver: using known distfile $curfile.\n"
		return 0
	fi
	return 1
}

try_mirrors() {
	local curfile="$1" distfile="$2" cksum="$3" f="$4" mirror_list="$5"
	local filesum basefile mirror path scheme good
	[ -z "$mirror_list" ] && return 1
	basefile="${f##*/}"
	for mirror in $mirror_list; do
		scheme="file"
		if [[ $mirror == *://* ]]; then
			scheme="${mirror%%:/*}"
			path="${mirror#${scheme}://}"
		else
			path="$mirror"
		fi
		if [ "$scheme" == "file" ]; then
			# Skip file:// mirror locations (/some/where or file:///some/where)
			# where the specified directory does not exist
			if [ ! -d "$path" ]; then
				msg_warn "$pkgver: mount point $path does not exist...\n"
				continue
			fi
		fi
		if [[ "$mirror" == *sources.voidlinux.* ]]; then
			# For sources.voidlinux.* append the subdirectory
			mirror="$mirror/$pkgname-$version"
		fi
		msg_normal "$pkgver: fetching distfile '$curfile' from mirror '$mirror'...\n"
		$fetch_cmd "$mirror/$curfile"
		# If basefile was not found, but a curfile file may exist, try to fetch it
		# if [ ! -f "$distfile" -a "$basefile" != "$curfile" ]; then
		# 	msg_normal "$pkgver: fetching distfile '$basefile' from mirror '$mirror'...\n"
		# 	$fetch_cmd "$mirror/$basefile"
		# fi
		[ ! -f "$distfile" ] && continue
		flock -n ${distfile}.part rm -f ${distfile}.part
		filesum=$(${XBPS_DIGEST_CMD} "$distfile")
		if [ "$cksum" == "$filesum" ]; then
			return 0
		fi
		msg_normal "$pkgver: checksum failed - removing '$curfile'...\n"
		rm -f ${distfile}
	done
	return 1
}

try_urls() {
	local curfile="$1"
	local good=
	for i in ${_file_idxs["$curfile"]}; do
		local cksum=${_checksums["$i"]}
		local url=${_distfiles["$i"]}

		# If distfile does not exist, download it from the original location.
		if [[ "$FTP_RETRIES" && "${url}" =~ ^ftp:// ]]; then
			max_retries="$FTP_RETRIES"
		else
			max_retries=1
		fi
		for retry in $(seq 1 1 $max_retries); do
			if [ ! -f "$distfile" ]; then
				if [ "$retry" == 1 ]; then
					msg_normal "$pkgver: fetching distfile '$curfile' from '$url'...\n"
				else
					msg_normal "$pkgver: fetch attempt $retry of $max_retries...\n"
				fi
				flock "${distfile}.part" $fetch_cmd "$url"
			fi
		done

		if [ ! -f "$distfile" ]; then
			continue
		fi

		# distfile downloaded, verify sha256 hash.
		flock -n "${distfile}.part" rm -f "${distfile}.part"
		verify_cksum "$curfile" "$distfile" "$cksum"
		return 0
	done
	return 1
}

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"
	local dfcount=0 dfgood=0 errors=0 max_retries

	local -a _distfiles=($distfiles)
	local -a _checksums=($checksum)
	local -A _file_idxs

	# Create a map from target file to index in _distfiles/_checksums
	for i in ${!_distfiles[@]}; do
		f="${_distfiles[$i]}"
		curfile="${f#*>}"
		curfile="${curfile##*/}"
		_file_idxs["$curfile"]+=" $i"
	done

	if [[ ! -d "$srcdir" ]]; then
		mkdir -p -m775 "$srcdir"
		chgrp $(id -g) "$srcdir"
	fi

	cd $srcdir || msg_error "$pkgver: cannot change dir to $srcdir!\n"

	# Disable trap on ERR; the code is smart enough to report errors and abort.
	trap - ERR
	# Detect bsdtar and GNU tar (in that order of preference)
	TAR_CMD="$(command -v bsdtar)"
	if [[ -z "$TAR_CMD" ]]; then
		TAR_CMD="$(command -v tar)"
	fi

	# Detect distfiles with obsolete checksum and purge them from the cache
	for f in ${!_file_idxs[@]}; do
		distfile="$srcdir/$f"
		for i in ${_file_idxs["$f"]}; do
			if [[ -f $distfile ]]; then
				cksum=${_checksums["$i"]}
				if [[ ${cksum:0:1} = @ ]]; then
					cksum=${cksum:1}
					filesum=$(contents_cksum "$distfile")
				else
					filesum=$(${XBPS_DIGEST_CMD} "$distfile")
				fi
				if [[ $cksum = $filesum ]]; then
					dfgood=$((dfgood + 1))
				else
					inode=$(stat_inode "$distfile")
					msg_warn "$pkgver: wrong checksum found for ${curfile} - purging\n"
					find ${XBPS_SRCDISTDIR} -inum ${inode} -delete -print
				fi
			fi
			dfcount=$((dfcount + 1))
		done
	done

	# We're done, if all distfiles were found and had good checksums
	[[ $dfcount -eq $dfgood ]] && return

	# Download missing distfiles and verify their checksums
	for curfile in ${!_file_idxs[@]}; do
		distfile="$srcdir/$curfile"
		set -- ${_file_idxs["$curfile"]}
		i="$1"

		# If file lock cannot be acquired wait until it's available.
		while ! flock -w 1 "${distfile}.part" true; do
			msg_warn "$pkgver: ${curfile} is already being downloaded, waiting for 1s ...\n"
		done

		if [[ -f "$distfile" ]]; then
			continue
		fi

		# If distfile does not exist, try to link to it.
		if link_cksum "$curfile" "$distfile" "${_checksums[$i]}"; then
			continue
		fi

		# If distfile does not exist, download it from a mirror location.
		if try_mirrors "$curfile" "$distfile" "${_checksums[$i]}" "${_distfiles[$i]}" "$XBPS_DISTFILES_MIRROR"; then
			continue
		fi

		if ! try_urls "$curfile"; then
			if try_mirrors "$curfile" "$distfile" "${_checksums[$i]}" "${_distfiles[$i]}" "$XBPS_DISTFILES_FALLBACK"; then
				continue
			fi
			msg_error "$pkgver: failed to fetch '$curfile'.\n"
		fi
	done

	unset TAR_CMD

	if [[ $errors -gt 0 ]]; then
		msg_error "$pkgver: couldn't verify distfiles, exiting...\n"
	fi
}
