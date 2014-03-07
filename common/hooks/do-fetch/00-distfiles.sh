# This hook downloads the distfiles specified in a template by
# the $distfiles variable and then verifies its sha256 checksum comparing
# its value with the one stored in the $checksum variable.

verify_sha256_cksum() {
	local file="$1" origsum="$2" distfile="$3"

	[ -z "$file" -o -z "$cksum" ] && return 1

	msg_normal "$pkgver: verifying checksum for distfile '$file'... "
	filesum=$(${XBPS_DIGEST_CMD} $distfile)
	if [ "$origsum" != "$filesum" ]; then
		echo
		msg_red "SHA256 mismatch for '$file:'\n$filesum\n"
		return 1
	else
		msg_normal_append "OK.\n"
	fi
}

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"

	if [ ! -d "$srcdir" ]; then
		mkdir -p -m775 "$srcdir"
		chgrp $(id -g) "$srcdir"
	fi

	cd $srcdir || msg_error "$pkgver: cannot change dir to $srcdir!\n"

	# Disable trap on ERR; the code is smart enough to report errors and abort.
	trap - ERR

	for f in ${distfiles}; do
		curfile=$(basename $f)
		distfile="$srcdir/$curfile"
		while true; do
			flock -w 1 ${distfile}.part true
			if [ $? -eq 0 ]; then
				break
			fi
			msg_warn "$pkgver: ${distfile} is being already downloaded, waiting for 1s ...\n"
		done
		if [ -f "$distfile" ]; then
			flock -n ${distfile}.part rm -f ${distfile}.part
			for i in ${checksum}; do
				if [ $dfcount -eq $ckcount -a -n "$i" ]; then
					cksum=$i
					found=yes
					break
				fi
				ckcount=$(($ckcount + 1))
			done
			if [ -z $found ]; then
				msg_error "$pkgver: cannot find checksum for $curfile.\n"
			fi

			verify_sha256_cksum $curfile $cksum $distfile
			errors=$(($errors + 1))
			unset cksum found
			ckcount=0
			dfcount=$(($dfcount + 1))
			continue
		fi

		msg_normal "$pkgver: fetching distfile '$curfile'...\n"

		if [ -n "$distfiles" ]; then
			localurl="$f"
		else
			localurl="$url/$curfile"
		fi

		flock ${distfile}.part $XBPS_FETCH_CMD $localurl
		if [ $? -ne 0 ]; then
			unset localurl
			if [ ! -f $distfile ]; then
				msg_error "$pkgver: couldn't fetch $curfile.\n"
			else
				msg_error "$pkgver: there was an error fetching $curfile.\n"
			fi
		else
			unset localurl
			#
			# XXX duplicate code.
			#
			for i in ${checksum}; do
				if [ $dfcount -eq $ckcount -a -n "$i" ]; then
					cksum=$i
					found=yes
					break
				fi
				ckcount=$(($ckcount + 1))
			done
			if [ -z $found ]; then
				msg_error "$pkgver: cannot find checksum for $curfile.\n"
			fi
			verify_sha256_cksum $curfile $cksum $distfile
			errors=$(($errors + 1))
			unset cksum found
			ckcount=0
		fi
		dfcount=$(($dfcount + 1))
	done

	if [ "$errors" -gt 0 ]; then
		msg_error "$pkgver: couldn't verify distfiles, exiting...\n"
	fi
}
