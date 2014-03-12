# This hook downloads the distfiles specified in a template by
# the $distfiles variable and then verifies its sha256 checksum comparing
# its value with the one stored in the $checksum variable.

verify_cksum() {
	local curfile="$1" distfile="$2" dfcount="$3" filesum ckcount cksum found i

	ckcount=0
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

	msg_normal "$pkgver: verifying checksum for distfile '$curfile'... "
	filesum=$(${XBPS_DIGEST_CMD} $distfile)
	if [ "$cksum" != "$filesum" ]; then
		echo
		msg_red "SHA256 mismatch for '$curfile:'\n$filesum\n"
		errors=$(($errors + 1))
	else
		msg_normal_append "OK.\n"
	fi
}

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"
	local dfcount=0 errors=0

	if [ ! -d "$srcdir" ]; then
		mkdir -p -m775 "$srcdir"
		chgrp $(id -g) "$srcdir"
	fi

	cd $srcdir || msg_error "$pkgver: cannot change dir to $srcdir!\n"

	# Disable trap on ERR; the code is smart enough to report errors and abort.
	trap - ERR

	for f in ${distfiles}; do
		localurl="${f%>*}"
		curfile=$(basename "${f#*>}")
		distfile="$srcdir/$curfile"

		# If file lock cannot be acquired wait until it's available.
		while true; do
			flock -w 1 ${distfile}.part true
			[ $? -eq 0 ] && break
			msg_warn "$pkgver: ${curfile} is being already downloaded, waiting for 1s ...\n"
		done
		# If distfile does not exist download it.
		if [ ! -f "$distfile" ]; then
			msg_normal "$pkgver: fetching distfile '$curfile'...\n"
			flock "${distfile}.part" $XBPS_FETCH_CMD $localurl
			if [ ! -f "$distfile" ]; then
				msg_error "$pkgver: failed to fetch $curfile.\n"
			fi
		fi
		# distfile downloaded, verify sha256 hash.
		flock -n ${distfile}.part rm -f ${distfile}.part
		verify_cksum $curfile $distfile $dfcount
		dfcount=$(($dfcount + 1))
	done

	if [ $errors -gt 0 ]; then
		msg_error "$pkgver: couldn't verify distfiles, exiting...\n"
	fi
}
