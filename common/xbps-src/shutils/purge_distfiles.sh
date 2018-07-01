# Scan srcpkgs/*/template for hashes and distfiles to determine
# obsolete sources/by_sha256 files and their corresponding
# sources/<pkgname>-<version> files that can be purged


purge_distfiles() {
	readonly HASHLEN=64
	if [ -z "$XBPS_SRCDISTDIR" ]; then
		msg_error "The variable \$XBPS_SRCDISTDIR is not set."
		exit 1
	fi
	#
	# Scan all templates for their current distfiles and checksums (hashes)
	#
	declare -A my_hashes
	templates=(srcpkgs/*/template)
	max=${#templates[@]}
	cur=0
	if [ -z "$max" ]; then
		msg_error "No srcpkgs/*/template files found. Wrong working directory?"
		exit 1
	fi
	percent=-1
	for template in ${templates[@]}; do
		pkg=${template#*/}
		pkg=${pkg%/*}
		if [ ! -L "srcpkgs/$pkg" ]; then
			checksum="$(grep -Ehrow [0-9a-f]{$HASHLEN} ${template}|sort|uniq)"
			read -a _my_hashes <<< ${checksum}
			i=0
			while [ -n "${_my_hashes[$i]}" ]; do
				hash="${_my_hashes[$i]}"
				[ -z "${my_hashes[$hash]}" ] && my_hashes[$hash]=$template
				i=$((i + 1))
			done
		fi
		cur=$((cur + 1))
		pnew=$((100 * cur / max))
		if [ $pnew -ne $percent ]; then
			percent=$pnew
			printf "\rScanning templates  : %3d%% (%d/%d)" $percent $cur $max
		fi
	done
	echo
	echo "Number of hashes    : ${#my_hashes[@]}"

	#
	# Collect inodes of all distfiles in $XBPS_SRCDISTDIR
	#
	declare -A inodes
	distfiles=($XBPS_SRCDISTDIR/*/*)
	max=${#distfiles[@]}
	if [ -z "$max" ]; then
		msg_error "No distfiles files found in '$XBPS_SRCDISTDIR'"
		exit 1
	fi
	cur=0
	percent=-1
	for distfile in ${distfiles[@]}; do
		inode=$(stat "$distfile" --printf "%i")
		if [ -z "${inodes[$inode]}" ]; then
			inodes[$inode]="$distfile"
		else
			inodes[$inode]+="|$distfile"
		fi
		cur=$((cur + 1))
		pnew=$((100 * cur / max))
		if [ $pnew -ne $percent ]; then
			percent=$pnew
			printf "\rCollecting inodes   : %3d%% (%d/%d)" $percent $cur $max
		fi
	done
	echo

	hashes=($XBPS_SRCDISTDIR/by_sha256/*)
	for file in ${hashes[@]}; do
		hash_distfile=${file##*/}
		hash=${hash_distfile:0:$HASHLEN}
		[ -n "${my_hashes[$hash]}" ] && continue
		inode=$(stat "$file" --printf "%i")
		echo "Obsolete $hash (inode: $inode)"
		( IFS="|"; for f in ${inodes[$inode]}; do rm -v "$f"; rmdir "${f%/*}" 2>/dev/null; done )
	done
	echo "Done."
}
