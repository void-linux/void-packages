#!/bin/sh
#
# Builds a binary package from an installed xbps package in the
# destination directory. This binary package is just a simple tar(1)
# archive with gzip, bzip2 or lzma compression (all compression
# modes that libarchive supports).
#
# Passed argument: pkgname.

write_metadata()
{
	local destdir=$XBPS_DESTDIR/$pkgname-$version

	if [ ! -d "$destdir" ]; then
		echo "ERROR: $pkgname not installed into destdir."
		exit 1
	fi

	# Write the files list.
	local TMPFLIST=$(mktemp -t flist.XXXXXXXXXX) || exit 1
	find $destdir | sort -ur | \
		sed -e "s|$destdir||g;s|^\/$||g;/^$/d" > $TMPFLIST

	# Write the property list file.
	local TMPFPROPS=$(mktemp -t fprops.XXXXXXXXXX) || exit 1

	cat > $TMPFPROPS <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>architecture</key>
	<string>$(uname -m)</string>
	<key>installed_size</key>
	<integer>$(du -sb $destdir|awk '{print $1}')</integer>
_EOF
	# Dependencies
	if [ -n "$run_depends" ]; then
		printf "\t<key>run_depends</key>\n" >> $TMPFPROPS
		printf "\t<array>\n" >> $TMPFPROPS
		for f in ${run_depends}; do
			printf "\t\t<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "\t</array>\n" >> $TMPFPROPS
	fi

	# Configuration files
	if [ -n "$config_files" ]; then
		printf "\t<key>config_files</key>\n" >> $TMPFPROPS
		printf "\t<array>\n" >> $TMPFPROPS
		for f in ${config_files}; do
			printf "\t\t<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "\t</array>\n" >> $TMPFPROPS
	fi

	# Terminate the property list file.
	printf "</dict>\n</plist>\n" >> $TMPFPROPS

	# Write metadata files into destdir and cleanup.
	if [ ! -d $destdir/xbps-metadata ]; then
		mkdir -p $destdir/xbps-metadata
	fi

	cp -f $TMPFLIST $destdir/xbps-metadata/flist
	cp -f $TMPFPROPS $destdir/xbps-metadata/props.plist
	chmod 644 $destdir/xbps-metadata/*
	rm -f $TMPFLIST $TMPFPROPS
}

make_archive()
{
	local destdir=$XBPS_DESTDIR/$pkgname-$version
	local pkgsdir=$XBPS_DISTRIBUTIONDIR/packages

	cd $destdir || exit 1

	tar cfjp $destdir-xbps.tbz2 .
	[ ! -d $pkgsdir ] && mkdir -p $pkgsdir
	mv -f $destdir-xbps.tbz2 $pkgsdir

	echo "=> Built package: $pkgname-$version-xbps.tbz2."
}

pkg=$1
if [ -z "$pkg" ]; then
	echo "ERROR: missing package name as argument."
	exit 1
fi

if [ -z "$XBPS_DISTRIBUTIONDIR" ]; then
	echo "ERROR: XBPS_DISTRIBUTIONDIR not set."
	exit 1
fi

if [ -z "$XBPS_DESTDIR" ]; then
	echo "ERROR: XBPS_DESTDIR not set."
	exit 1
fi

if [ ! -f $XBPS_DISTRIBUTIONDIR/templates/$pkg.tmpl ]; then
	echo "ERROR: missing package template file."
	exit 1
fi

. $XBPS_DISTRIBUTIONDIR/templates/$pkg.tmpl

write_metadata
make_archive

return 0
