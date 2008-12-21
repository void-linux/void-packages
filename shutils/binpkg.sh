#-
# Copyright (c) 2008 Juan Romero Pardines.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-

#
# This function writes the metadata files into package's destdir,
# these will be used for binary packages.
#
xbps_write_metadata_pkg()
{
	local destdir=$XBPS_DESTDIR/$pkgname-$version
	local metadir=$destdir/var/cache/xbps/metadata/$pkgname

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
	<key>pkgname</key>
	<string>$pkgname</string>
	<key>version</key>
	<string>$version</string>
	<key>architecture</key>
	<string>$xbps_machine</string>
	<key>installed_size</key>
	<integer>$(du -sb $destdir|awk '{print $1}')</integer>
	<key>maintainer</key>
	<string>$(echo $maintainer|sed -e 's|<|[|g;s|>|]|g')</string>
	<key>short_desc</key>
	<string>$short_desc</string>
	<key>long_desc</key>
	<string>$long_desc</string>
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
	if [ -n "$conf_files" ]; then
		printf "\t<key>conf_files</key>\n" >> $TMPFPROPS
		printf "\t<array>\n" >> $TMPFPROPS
		for f in ${conf_files}; do
			printf "\t\t<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "\t</array>\n" >> $TMPFPROPS
	fi
	# Keep directories while removing.
	if [ -n "$keep_dirs" ]; then
		printf "\t<key>keep_dirs</key>\n" >> $TMPFPROPS
		printf "\t<array>\n" >> $TMPFPROPS
		for f in ${keep_dirs}; do
			printf "\t\t<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "\t</array>\n" >> $TMPFPROPS
	fi

	# Terminate the property list file.
	printf "</dict>\n</plist>\n" >> $TMPFPROPS

	if [ ! -d $metadir ]; then
		mkdir -p $metadir >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "ERROR: you don't have enough perms for this."
			rm -f $TMPFLIST $TMPFPROPS
			exit 1
		fi
	fi

	# Write metadata files and cleanup.
	cp -f $TMPFLIST $metadir/flist
	cp -f $TMPFPROPS $metadir/props.plist
	chmod 644 $metadir/*
	rm -f $TMPFLIST $TMPFPROPS
}

#
# This function builds a binary package from an installed xbps
# package in destdir.
#
xbps_make_binpkg()
{
	local destdir=$XBPS_DESTDIR/$pkgname-$version
	local binpkg=$pkgname-$version.$xbps_machine.xbps

	cd $destdir || exit 1

	run_rootcmd tar cfjp $XBPS_DESTDIR/$binpkg .
	[ ! -d $XBPS_PACKAGESDIR ] && mkdir -p $XBPS_PACKAGESDIR
	mv -f $XBPS_DESTDIR/$binpkg $XBPS_PACKAGESDIR

	echo "=> Built package: $binpkg"
}
