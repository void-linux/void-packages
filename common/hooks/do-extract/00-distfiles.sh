# This hook extracts $distfiles into $XBPS_BUILDDIR if $distfiles and $checksum
# variables are set.

hook() {
	local srcdir="$XBPS_SRCDISTDIR/$pkgname-$version"
	local f j curfile found extractdir innerdir innerfile num_dirs
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

	# Disable trap on ERR; the code is smart enough to report errors and abort.
	trap - ERR

	TAR_CMD="$(command -v bsdtar)"
	[ -z "$TAR_CMD" ] && TAR_CMD="$(command -v tar)"
	[ -z "$TAR_CMD" ] && msg_error "xbps-src: no suitable tar cmd (bsdtar, tar)\n"

	extractdir=$(mktemp -d "$XBPS_BUILDDIR/.extractdir-XXXXXXX") ||
		msg_error "Cannot create temporary dir for do-extract\n"

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
		vsrcextract --no-strip-components -C "$extractdir" "$curfile"
	done

	cd "$extractdir"
	# find "$extractdir" -mindepth 1 -maxdepth 1 -printf '1\n' | wc -l
	# However, it requires GNU's find
	num_dirs=0
	for f in * .*; do
		if [ -e "$f" ] || [ -L "$f" ]; then
			case "$f" in
			. | ..) ;;
			*)
				innerdir="$f"
				num_dirs=$(( num_dirs + 1 ))
				;;
			esac
		fi
	done
	# Special case for num_dirs = 2, and it contains metadata
	if [ "$num_dirs" != 2 ] || [ "$create_wrksrc" ]; then
		:
	elif grep -q 'xmlns="http://pear[.]php[.]net/dtd/package' package.xml 2>/dev/null
	then
		# PHP modules' metadata
		rm -f package.xml
		for f in */; do innerdir="$f"; done
		num_dirs=1
	else
		for f in *; do
			# AppleDouble encoded Macintosh file
			if [ -e "$f" ] && [ -e "._$f" ]; then
				rm -f "._$f"
				num_dirs=1
				innerdir="$f"
				break
			fi
		done
	fi
	rm -rf "$wrksrc"
	innerdir="$extractdir/$innerdir"
	cd "$XBPS_BUILDDIR"
	if [ "$num_dirs" = 1 ] && [ -d "$innerdir" ] && [ -z "$create_wrksrc" ]; then
		# rename the subdirectory (top-level of distfiles) to $wrksrc
		mv "$innerdir" "$wrksrc" &&
		rmdir "$extractdir"
	else
		mv "$extractdir" "$wrksrc"
	fi ||
		msg_error "$pkgver: failed to move sources to $wrksrc\n"
}
