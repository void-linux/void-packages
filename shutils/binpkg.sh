#-
# Copyright (c) 2008-2009 Juan Romero Pardines.
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

write_metadata_flist_header()
{
	local file="$1"

	[ -z "$file" ] && return 1

	cat > $file <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>filelist</key>
<array>
_EOF

}

xbps_write_metadata_pkg()
{
	local pkg="$1"
	local subpkg=

	for subpkg in ${subpackages}; do
		if [ "${pkg}" != "${sourcepkg}" ] && \
		   [ "${pkg}" != "${sourcepkg}-${subpkg}" ]; then
			continue
		fi
		check_installed_pkg ${sourcepkg}-${subpkg}-${version}
		[ $? -eq 0 ] && continue

		if [ ! -f $XBPS_TEMPLATESDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find subpackage template!"
		fi
		unset run_depends conf_files keep_dirs noarch install_priority
		. $XBPS_TEMPLATESDIR/${sourcepkg}/${subpkg}.template
		pkgname=${sourcepkg}-${subpkg}
		xbps_write_metadata_pkg_real
		run_template ${sourcepkg}
		[ "${pkg}" = "${sourcepkg}-${subpkg}" ] && break
	done

	[ -n "${subpackages}" ] && [ "$pkg" != "${sourcepkg}" ] && return $?

	if [ "$build_style" = "meta-template" -a -z "${run_depends}" ]; then
		for subpkg in ${subpackages}; do
			run_depends="$run_depends ${sourcepkg}-${subpkg}-${version}"
		done
	fi
	xbps_write_metadata_pkg_real
}

#
# This function writes the metadata files into package's destdir,
# these will be used for binary packages.
#
xbps_write_metadata_pkg_real()
{
	local destdir=$XBPS_DESTDIR/$pkgname-$version
	local metadir=$destdir/var/db/xbps/metadata/$pkgname
	local f i j arch prioinst TMPFLIST TMPFPLIST
	local fpattern="s|$destdir||g;s|^\./$||g;/^$/d"

	if [ ! -d "$destdir" ]; then
		echo "ERROR: $pkgname not installed into destdir."
		exit 1
	fi

	if [ -n "$install_priority" ]; then
		prioinst=$install_priority
	else
		prioinst=0
	fi

	if [ -n "$noarch" ]; then
		arch=noarch
	else
		arch=$xbps_machine
	fi

	# Write the files.plist file.
	TMPFLIST=$(mktemp -t flist.XXXXXXXXXX) || exit 1
	TMPFPLIST=$(mktemp -t fplist.XXXXXXXXXX) || exit 1

	msg_normal "Writing package metadata for $pkgname-$version..."

	write_metadata_flist_header $TMPFPLIST

	# Pass 1: add links.
	for f in $(find $destdir -type l); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		printf "$j\n" >> $TMPFLIST
		printf "<dict>\n" >> $TMPFPLIST
		printf "<key>file</key>\n" >> $TMPFPLIST
		printf "<string>$j</string>\n" >> $TMPFPLIST
		printf "<key>type</key>\n" >> $TMPFPLIST
		printf "<string>link</string>\n" >> $TMPFPLIST
		printf "</dict>\n" >> $TMPFPLIST
	done

	# Pass 2: add regular files.
	for f in $(find $destdir -type f); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		printf "$j\n" >> $TMPFLIST
		printf "<dict>\n" >> $TMPFPLIST
		printf "<key>file</key>\n" >> $TMPFPLIST
		printf "<string>$j</string>\n" >> $TMPFPLIST
		printf "<key>type</key>\n" >> $TMPFPLIST
		printf "<string>file</string>\n" >> $TMPFPLIST
		printf "<key>sha256</key>\n" >> $TMPFPLIST
		printf "<string>$(xbps-digest $f)</string>\n"  >> $TMPFPLIST
		for i in ${conf_files}; do
			if [ "$j" = "$i" ]; then
				printf "<key>conf_file</key>\n"  >> $TMPFPLIST
				printf "<true/>\n" >> $TMPFPLIST
				break
			fi
		done
		printf "</dict>\n" >> $TMPFPLIST
	done

	# Pass 3: add directories.
	for f in $(find $destdir -type d|sort -ur); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		printf "$j\n" >> $TMPFLIST
		printf "<dict>\n" >> $TMPFPLIST
		printf "<key>file</key>\n" >> $TMPFPLIST
		printf "<string>$j</string>\n" >> $TMPFPLIST
		printf "<key>type</key>\n" >> $TMPFPLIST
		printf "<string>dir</string>\n" >> $TMPFPLIST
		for i in ${keep_dirs}; do
			if [ "$j" = "$i" ]; then
				printf "<key>keep</key>\n" >> $TMPFPLIST
				printf "<true/>\n" >> $TMPFPLIST
				break
			fi
		done
		printf "</dict>\n" >> $TMPFPLIST
	done
	printf "</array>\n</dict>\n</plist>\n" >> $TMPFPLIST
	sed -i -e /^$/d $TMPFLIST

	# Write the props.plist file.
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
<string>$arch</string>
<key>priority</key>
<integer>$prioinst</integer>
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
		printf "<key>run_depends</key>\n" >> $TMPFPROPS
		printf "<array>\n" >> $TMPFPROPS
		for f in ${run_depends}; do
			printf "<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "</array>\n" >> $TMPFPROPS
	fi

	# Configuration files
	if [ -n "$conf_files" ]; then
		printf "<key>conf_files</key>\n" >> $TMPFPROPS
		printf "<array>\n" >> $TMPFPROPS
		for f in ${conf_files}; do
			printf "<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "</array>\n" >> $TMPFPROPS
	fi
	# Keep directories while removing.
	if [ -n "$keep_dirs" ]; then
		printf "<key>keep_dirs</key>\n" >> $TMPFPROPS
		printf "<array>\n" >> $TMPFPROPS
		for f in ${keep_dirs}; do
			printf "<string>$f</string>\n" >> $TMPFPROPS
		done
		printf "</array>\n" >> $TMPFPROPS
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
	cp -f $TMPFPLIST $metadir/files.plist
	cp -f $TMPFPROPS $metadir/props.plist
	$XBPS_REGPKGDB_CMD sanitize-plist $metadir/files.plist
	$XBPS_REGPKGDB_CMD sanitize-plist $metadir/props.plist
	chmod 644 $metadir/*
	rm -f $TMPFLIST $TMPFPLIST $TMPFPROPS

	if [ -f "$XBPS_TEMPLATESDIR/$pkgname/INSTALL" ]; then
		cp -f $XBPS_TEMPLATESDIR/$pkgname/INSTALL $destdir
		chmod +x $destdir/INSTALL
	fi
	if [ -f "$XBPS_TEMPLATESDIR/$pkgname/REMOVE" ]; then
		cp -f $XBPS_TEMPLATESDIR/$pkgname/REMOVE $metadir
		chmod +x $metadir/REMOVE
	fi
}

xbps_make_binpkg()
{
	local pkg="$1"
	local subpkg=

	for subpkg in ${subpackages}; do
		if [ "$pkg" = "$pkgname-$subpkg" ]; then
			. $XBPS_TEMPLATESDIR/$pkgname/$subpkg.template
			pkgname=${sourcepkg}-${subpkg}
			xbps_make_binpkg_real
			return $?
		fi
		run_template ${sourcepkg}
	done

	xbps_make_binpkg_real
	return $?
}

#
# This function builds a binary package from an installed xbps
# package in destdir.
#
xbps_make_binpkg_real()
{
	local destdir=$XBPS_DESTDIR/$pkgname-$version
	local binpkg=
	local pkgdir=
	local arch=
	local use_sudo=

	cd $destdir || exit 1

	if [ -n "$noarch" ]; then
		arch=noarch
	else
		arch=$xbps_machine
	fi

	if [ -n "$base_chroot" ]; then
		use_sudo=no
	else
		use_sudo=yes
	fi

	binpkg=$pkgname-$version.$arch.xbps
	pkgdir=$XBPS_PACKAGESDIR/$arch

	if [ -x ./INSTALL ]; then
		#
		# Make sure that INSTALL is the first file on the archive,
		# this is to ensure that it's run before any other file is
		# unpacked.
		#
		run_rootcmd $use_sudo tar cfp $XBPS_DESTDIR/$binpkg ./INSTALL && \
		run_rootcmd $use_sudo tar rfp $XBPS_DESTDIR/$binpkg . \
			--exclude "./INSTALL" && \
			bzip2 -9 $XBPS_DESTDIR/$binpkg && \
			mv $XBPS_DESTDIR/$binpkg.bz2 $XBPS_DESTDIR/$binpkg
	else
		run_rootcmd $use_sudo tar cfp $XBPS_DESTDIR/$binpkg . && \
			bzip2 -9 $XBPS_DESTDIR/$binpkg && \
			mv $XBPS_DESTDIR/$binpkg.bz2 $XBPS_DESTDIR/$binpkg
	fi
	# Disabled for now.
	#		--exclude "./var/db/xbps/metadata/*/flist" .
	#
	if [ $? -eq 0 ]; then
		[ ! -d $pkgdir ] && mkdir -p $pkgdir
		mv -f $XBPS_DESTDIR/$binpkg $pkgdir
		echo "=> Built package: $binpkg"
	fi

	return $?
}
