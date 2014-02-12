# This hook applies patches from "patches" directory.

_process_patch() {
	local _args= _patch= i=$1

	_args="-Np0"
	_patch=$(basename $i)
	if [ -f $PATCHESDIR/${_patch}.args ]; then
		_args=$(cat $PATCHESDIR/${_patch}.args)
	elif [ -n "$patch_args" ]; then
		_args=$patch_args
	fi
	cp -f $i $wrksrc

	# Try to guess if its a compressed patch.
	if $(echo $i|grep -q '.diff.gz'); then
		gunzip $wrksrc/${_patch}
		_patch=${_patch%%.gz}
	elif $(echo $i|grep -q '.patch.gz'); then
		gunzip $wrksrc/${_patch}
		_patch=${_patch%%.gz}
	elif $(echo $i|grep -q '.diff.bz2'); then
		bunzip2 $wrksrc/${_patch}
		_patch=${_patch%%.bz2}
	elif $(echo $i|grep -q '.patch.bz2'); then
		bunzip2 $wrksrc/${_patch}
		_patch=${_patch%%.bz2}
	elif $(echo $i|grep -q '.diff'); then
		:
	elif $(echo $i|grep -q '.patch'); then
		:
	else
		msg_warn "$pkgver: unknown patch type: $i.\n"
		continue
	fi

	cd $wrksrc
	patch -sl ${_args} -i ${_patch} 2>/dev/null
	msg_normal "$pkgver: patch applied: ${_patch}.\n"
}

hook() {
	if [ ! -d "$wrksrc" ]; then
		return 0
	fi
	if [ -r $PATCHESDIR/series ]; then
		cat $PATCHESDIR/series | while read f; do
			_process_patch "$PATCHESDIR/$f"
		done
	else
		for f in $PATCHESDIR/*; do
			[ ! -f $f ] && continue
			if $(echo $f|grep -Eq '^.*.args$'); then
				continue
			fi
			_process_patch $f
		done
	fi
}
