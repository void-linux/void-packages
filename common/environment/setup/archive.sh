vextract() {
	local sc=--strip-components=1
	local dst=
	while [ "$#" -ne 1 ]; do
		case "$1" in
		-C)
			if [ -z "$2" ]; then
				msg_error "$pkgver: vextract -C <directory>.\n"
			fi
			dst="$2"
			mkdir -p "$dst"
			shift 2
			;;
		--no-strip-components)
			sc=
			shift
			;;
		--strip-components=*)
			sc="$1"
			shift
			;;
		--)
			shift; break ;;
		*)
			break ;;
		esac
	done

	local TAR_CMD="${tar_cmd}"
	local sfx
	local archive="$1"
	local ret=0

	[ -z "$TAR_CMD" ] && TAR_CMD="$(command -v bsdtar)"
	[ -z "$TAR_CMD" ] && TAR_CMD="$(command -v tar)"
	[ -z "$TAR_CMD" ] && msg_error "xbps-src: no suitable tar cmd (bsdtar, tar)\n"
	case "$archive" in
	*.tar.lzma)   sfx="txz";;
	*.tar.lz)     sfx="tlz";;
	*.tlz)        sfx="tlz";;
	*.tar.xz)     sfx="txz";;
	*.txz)        sfx="txz";;
	*.tar.bz2)    sfx="tbz";;
	*.tbz)        sfx="tbz";;
	*.tar.gz)     sfx="tgz";;
	*.tgz)        sfx="tgz";;
	*.tar.zst)    sfx="tzst";;
	*.tzst)       sfx="tzst";;
	*.gz)         sfx="gz";;
	*.xz)         sfx="xz";;
	*.bz2)        sfx="bz2";;
	*.zst)        sfx="zst";;
	*.tar)        sfx="tar";;
	*.zip)        sfx="zip";;
	*.rpm)        sfx="rpm";;
	*.deb)        sfx="deb";;
	*.patch)      sfx="txt";;
	*.diff)       sfx="txt";;
	*.txt)        sfx="txt";;
	*.sh)         sfx="txt";;
	*.7z)	      sfx="7z";;
	*.gem)	      sfx="gem";;
	*.crate)      sfx="crate";;
	*) msg_error "$pkgver: unknown distfile suffix for $archive.\n";;
	esac

	case ${sfx} in
	tar|txz|tbz|tlz|tgz|tzst|crate)
		$TAR_CMD ${sc:+"$sc"} ${dst:+-C "$dst"} -x \
			--no-same-permissions --no-same-owner \
			-f $archive
		;;
	gz|bz2|xz|zst)
		cp -f $archive "${dst:-.}"
		(
			if [ "$dst" ]; then cd "$dst"; fi
			case ${sfx} in
			gz)
				gunzip -f ${archive##*/}
				;;
			bz2)
				bunzip2 -f ${archive##*/}
				;;
			xz)
				unxz -f ${archive##*/}
				;;
			zst)
				unzstd ${archive##*/}
				;;
			esac
		)
		;;
	zip)
		if command -v unzip &>/dev/null; then
			unzip -o -q $archive ${dst:+-d "$dst"}
		elif command -v bsdtar &>/dev/null; then
			bsdtar ${sc:+"$sc"} ${dst:+-C "$dst"} -xf $archive
		else
			msg_error "$pkgver: cannot find unzip or bsdtar bin for extraction.\n"
		fi
		;;
	rpm)
		if ! command -v bsdtar &>/dev/null; then
			msg_error "$pkgver: cannot find bsdtar for extraction.\n"
		fi
		bsdtar ${sc:+"$sc"} ${dst:+-C "$dst"} -x \
			--no-same-permissions --no-same-owner -f $archive
		;;
	deb)
		if command -v bsdtar &>/dev/null; then
			bsdtar -x -O -f "$archive" "data.tar.*" |
			bsdtar ${sc:+"$sc"} ${dst:+-C "$dst"} -x \
				--no-same-permissions --no-same-owner -f -
		else
			msg_error "$pkgver: cannot find bsdtar for extraction.\n"
		fi
		;;
	txt)
		cp -f $archive "$dst"
		;;
	7z)
		if command -v 7z &>/dev/null; then
			7z x $archive -o"$dst"
		elif command -v bsdtar &>/dev/null; then
			bsdtar ${sc:+"$sc"} ${dst:+-C "$dst"} -xf $archive
		else
			msg_error "$pkgver: cannot find 7z or bsdtar bin for extraction.\n"
		fi
		;;
	gem)
		$TAR_CMD -xOf $archive data.tar.gz |
			$TAR_CMD ${sc:+"$sc"} ${dst:+-C "$dst"} -xz -f -
		;;
	*)
		msg_error "$pkgver: cannot guess $archive extract suffix. ($sfx)\n"
		;;
	esac
	if [ "$?" -ne 0 ]; then
		msg_error "$pkgver: extracting $archive.\n"
	fi
}

vsrcextract() {
	local sc=--strip-components=1
	local dst=
	while [ "$#" -ge 1 ]; do
		case "$1" in
		-C)
			if [ -z "$2" ]; then
				msg_error "$pkgver: vsrcextract -C <directory>.\n"
			fi
			dst="$2"
			shift 2
			;;
		--no-strip-components|--strip-components=*)
			sc="$1"
			shift
			;;
		*)
			break ;;
		esac
	done
	local archive="$1"
	shift
	vextract "$sc" ${dst:+-C "$dst"} \
		"${XBPS_SRCDISTDIR}/${pkgname}-${version}/$archive" "$@"
}

vtar() {
	bsdtar "$@"
}

vsrccopy() {
	local _tgt
	if [ $# -lt 2 ]; then
		msg_error "vsrccopy <file>... <target>"
	fi
	_tgt="${@: -1}"
	mkdir -p "$_tgt"
	while [ $# -gt 1 ]; do
		cp -a "${XBPS_SRCDISTDIR}/${pkgname}-${version}/$1" "$_tgt"
		shift
	done
}
