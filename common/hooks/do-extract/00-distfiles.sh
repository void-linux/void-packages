# This hook extracts $distfiles into $XBPS_BUILDDIR if $distfiles and $checksum
# variables are set.

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"

	if [ -z "$distfiles" -a -z "$checksum" ]; then
		mkdir -p $wrksrc
		exit 0
	fi

	# Check that distfiles are there before anything else.
	for f in ${distfiles}; do
		curfile=$(basename $f)
		if [ ! -f $srcdir/$curfile ]; then
			msg_error "$pkgver: cannot find ${curfile}, use 'xbps-src fetch' first.\n"
		fi
	done

	if [ -n "$create_wrksrc" ]; then
		mkdir -p ${wrksrc} || msg_error "$pkgver: failed to create wrksrc.\n"
	fi

	msg_normal "$pkgver: extracting distfile(s), please wait...\n"

	for f in ${distfiles}; do
		curfile=$(basename $f)
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

		if $(echo $f|grep -q '.tar.lzma'); then
			cursufx="txz"
		elif $(echo $f|grep -q '.tar.xz'); then
			cursufx="txz"
		elif $(echo $f|grep -q '.txz'); then
			cursufx="txz"
		elif $(echo $f|grep -q '.tar.bz2'); then
			cursufx="tbz"
		elif $(echo $f|grep -q '.tbz'); then
			cursufx="tbz"
		elif $(echo $f|grep -q '.tar.gz'); then
			cursufx="tgz"
		elif $(echo $f|grep -q '.tgz'); then
			cursufx="tgz"
		elif $(echo $f|grep -q '.gz'); then
			cursufx="gz"
		elif $(echo $f|grep -q '.bz2'); then
			cursufx="bz2"
		elif $(echo $f|grep -q '.tar'); then
			cursufx="tar"
		elif $(echo $f|grep -q '.zip'); then
			cursufx="zip"
		else
			msg_error "$pkgver: unknown distfile suffix for $curfile.\n"
		fi

		if [ -n "$create_wrksrc" ]; then
			extractdir="$wrksrc"
		else
			extractdir="$XBPS_BUILDDIR"
		fi

		case ${cursufx} in
		txz)
			unxz -cf $srcdir/$curfile | tar xf - -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		tbz)
			bunzip2 -cf $srcdir/$curfile | tar xf - -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		tgz)
			gunzip -cf $srcdir/$curfile | tar xf - -C $extractdir
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
			tar xf $srcdir/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
			fi
			;;
		zip)
			if command -v unzip 2>&1 >/dev/null; then
				unzip -q $srcdir/$curfile -d $extractdir
				if [ $? -ne 0 ]; then
					msg_error "$pkgver: extracting $curfile into $XBPS_BUILDDIR.\n"
				fi
			else
				msg_error "$pkgver: cannot find unzip bin for extraction.\n"
			fi
			;;
		*)
			msg_error "$pkgver: cannot guess $curfile extract suffix. ($cursufx)\n"
			;;
		esac
	done
}
