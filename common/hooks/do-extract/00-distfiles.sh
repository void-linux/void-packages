# This hook extracts $distfiles into $XBPS_BUILDDIR if $distfiles and $checksum
# variables are set.

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"

	if [ -z "$distfiles" -a -z "$checksum" ]; then
		mkdir -p $wrksrc
		return 0
	fi

	# Check that distfiles are there before anything else.
	for f in ${distfiles}; do
		curfile=$(basename "${f#*>}")
		if [ ! -f $srcdir/$curfile ]; then
			msg_error "$pkgver: cannot find ${curfile}, use 'xbps-src fetch' first.\n"
		fi
	done

	if [ -n "$create_wrksrc" ]; then
		mkdir -p ${wrksrc} || msg_error "$pkgver: failed to create wrksrc.\n"
	fi

	msg_normal "$pkgver: extracting distfile(s), please wait...\n"

	for f in ${distfiles}; do
		curfile=$(basename "${f#*>}")
		for j in ${skip_extraction}; do
			if [ "$curfile" = "$j" ]; then
				found=1
				break
			fi
		done
		if [ -n "$found" ]; then
			unset found
			continue
		fi

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

		if [ -n "$create_wrksrc" ]; then
			extractdir="$wrksrc"
		else
			extractdir="$XBPS_BUILDDIR"
		fi

		case ${cursufx} in
		txz|tbz|tlz|tgz|crate)
			tar -x --no-same-permissions --no-same-owner -f $srcdir/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		gz|bz2)
			cp -f $srcdir/$curfile $extractdir
			if [ "$cursufx" = "gz" ]; then
				cd $extractdir && gunzip $curfile
			else
				cd $extractdir && bunzip2 $curfile
			fi
			;;
		tar)
			tar -x --no-same-permissions --no-same-owner -f $srcdir/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		zip)
			if command -v unzip &>/dev/null; then
				unzip -o -q $srcdir/$curfile -d $extractdir
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find unzip bin for extraction.\n"
			fi
			;;
		rpm)
			if command -v rpmextract &>/dev/null; then
				cd $extractdir
				rpmextract $srcdir/$curfile
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find rpmextract for extraction.\n"
			fi
			;;
		txt)
			cp -f $srcdir/$curfile $extractdir
			;;
		7z)
			if command -v 7z &>/dev/null; then
				7z x $srcdir/$curfile -o$extractdir
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find 7z bin for extraction.\n"
			fi
			;;
		gem)
			tar -xOf $srcdir/$curfile data.tar.gz | tar -xz -C $extractdir --transform="s,^,$(basename $wrksrc)/,"
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		*)
			msg_error "$pkgver: cannot guess $curfile extract suffix. ($cursufx)\n"
			;;
		esac
	done
}
