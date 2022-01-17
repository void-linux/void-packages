# This hook extracts $distfiles into $XBPS_BUILDDIR if $distfiles and $checksum
# variables are set.

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"
	local f j curfile found extractdir
	local TAR_CMD

	if [ -z "$distfiles" -a -z "$checksum" ]; then
		mkdir -p "$wrksrc"
		return 0
	fi

	# Check that distfiles are there before anything else.
	for f in ${distfiles}; do
		curfile="${f#*>}"
		curfile="${curfile##*/}"
		if [ ! -f $srcdir/$curfile ]; then
			msg_error "$pkgver: cannot find ${curfile}, use 'xbps-src fetch' first.\n"
		fi
	done

	if [ -n "$create_wrksrc" ]; then
		mkdir -p "${wrksrc}" || msg_error "$pkgver: failed to create wrksrc.\n"
	fi

	# Disable trap on ERR; the code is smart enough to report errors and abort.
	trap - ERR

	TAR_CMD="$(command -v bsdtar)"
	[ -z "$TAR_CMD" ] && TAR_CMD="$(command -v tar)"
	[ -z "$TAR_CMD" ] && msg_error "xbps-src: no suitable tar cmd (bsdtar, tar)\n"

	msg_normal "$pkgver: extracting distfile(s), please wait...\n"

	for f in ${distfiles}; do
		curfile="${f#*>}"
		curfile="${curfile##*/}"
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
		*.xz)         cursufx="xz";;
		*.bz2)        cursufx="bz2";;
		*.tar)        cursufx="tar";;
		*.zip)        cursufx="zip";;
		*.rpm)        cursufx="rpm";;
		*.patch)      cursufx="txt";;
		*.diff)       cursufx="txt";;
		*.txt)        cursufx="txt";;
		*.sh)         cursufx="txt";;
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
		tar|txz|tbz|tlz|tgz|crate)
			$TAR_CMD -x --no-same-permissions --no-same-owner -f $srcdir/$curfile -C "$extractdir"
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		gz|bz2|xz)
			cp -f $srcdir/$curfile "$extractdir"
			cd "$extractdir"
			case ${cursufx} in
			gz)
				 gunzip -f $curfile
				;;
			bz2)
				bunzip2 -f $curfile
				;;
			*)
				unxz -f $curfile
				;;
			esac
			;;
		zip)
			if command -v unzip &>/dev/null; then
				unzip -o -q $srcdir/$curfile -d "$extractdir"
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			elif command -v bsdtar &>/dev/null; then
				bsdtar -xf $srcdir/$curfile -C "$extractdir"
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find unzip or bsdtar bin for extraction.\n"
			fi
			;;
		rpm)
			if command -v rpmextract &>/dev/null; then
				cd "$extractdir"
				rpmextract $srcdir/$curfile
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find rpmextract for extraction.\n"
			fi
			;;
		txt)
			if [ "$create_wrksrc" ]; then
				cp -f $srcdir/$curfile "$extractdir"
			else
				msg_error "$pkgname: ${curfile##*.} files can only be extracted when create_wrksrc is set\n"
			fi
			;;
		7z)
			if command -v 7z &>/dev/null; then
				7z x $srcdir/$curfile -o"$extractdir"
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			elif command -v bsdtar &>/dev/null; then
				bsdtar -xf $srcdir/$curfile -C "$extractdir"
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find 7z or bsdtar bin for extraction.\n"
			fi
			;;
		gem)
			case "$TAR_CMD" in
				*bsdtar)
					$TAR_CMD -xOf $srcdir/$curfile data.tar.gz | \
						$TAR_CMD -xz -C "$extractdir" -s ",^,${wrksrc##*/}/," -f -
					;;
				*)
					$TAR_CMD -xOf $srcdir/$curfile data.tar.gz | \
						$TAR_CMD -xz -C "$extractdir" --transform="s,^,${wrksrc##*/}/,"
					;;
			esac
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
