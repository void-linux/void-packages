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
	[ ! -f "$1" ] && return 1

	cat > $1 <<_EOF
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
	local subpkg spkgrev

	for subpkg in ${subpackages}; do
		if [ "${pkg}" != "${sourcepkg}" ] && \
		   [ "${pkg}" != "${sourcepkg}-${subpkg}" ]; then
			continue
		fi
		if [ -n "${revision}" ]; then
			spkgrev="${sourcepkg}-${subpkg}-${version}_${revision}"
		else
			spkgrev="${sourcepkg}-${subpkg}-${version}"
		fi
		check_installed_pkg ${spkgrev}
		[ $? -eq 0 ] && continue

		if [ ! -f $XBPS_TEMPLATESDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find subpackage template!"
		fi
		unset run_depends conf_files keep_dirs noarch triggers \
			revision openrc_services
		. $XBPS_TEMPLATESDIR/${sourcepkg}/${subpkg}.template
		pkgname=${sourcepkg}-${subpkg}
		set_tmpl_common_vars
		xbps_write_metadata_pkg_real
		run_template ${sourcepkg}
		[ "${pkg}" = "${sourcepkg}-${subpkg}" ] && break
	done

	[ -n "${subpackages}" ] && [ "$pkg" != "${sourcepkg}" ] && return $?

	if [ "$build_style" = "meta-template" -a -z "${run_depends}" ]; then
		for subpkg in ${subpackages}; do
			if [ -n "${revision}" ]; then
				spkgrev="${sourcepkg}-${subpkg}-${version}_${revision}"
			else
				spkgrev="${sourcepkg}-${subpkg}-${version}"
			fi
			run_depends="${run_depends} ${spkgrev}"
		done
	fi
	set_tmpl_common_vars
	xbps_write_metadata_pkg_real
}

#
# This function writes the metadata files into package's destdir,
# these will be used for binary packages.
#
xbps_write_metadata_pkg_real()
{
	local metadir=${DESTDIR}/var/db/xbps/metadata/$pkgname
	local f i j arch dirat lnkat newlnk lver TMPFLIST TMPFPLIST
	local fpattern="s|${DESTDIR}||g;s|^\./$||g;/^$/d"

	if [ ! -d "${DESTDIR}" ]; then
		echo "ERROR: $pkgname not installed into destdir."
		exit 1
	fi

	if [ -n "$noarch" ]; then
		arch=noarch
	else
		arch=$xbps_machine
	fi

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	# Write the files.plist file.
	TMPFLIST=$(mktemp -t flist.XXXXXXXXXX) || exit 1
	TMPFPLIST=$(mktemp -t fplist.XXXXXXXXXX) || exit 1
	TMPINFOLIST=$(mktemp -t infolist.XXXXXXXXXX) || exit 1

        #
        # Find out if this package contains info files and compress
        # all them with gzip.
        #
	if [ -f ${DESTDIR}/usr/share/info/dir ]; then
		# Always remove this file if curpkg is not texinfo.
		if [ "$pkgname" != "texinfo" ]; then
			rm -f ${DESTDIR}/usr/share/info/dir
		fi
		# Add info-files trigger.
		triggers="info-files $triggers"

		for f in $(find -L ${DESTDIR}/usr/share/info -type f); do
			j=$(echo $f|sed -e "$fpattern")
			[ "$j" = "" ] && continue
			[ "$j" = "/usr/share/info/dir" ] && continue
			if $(echo $j|grep -q '.*.gz$'); then
				continue
			fi
			if [ -h ${DESTDIR}/$j ]; then
				dirat=$(dirname $j)
				lnkat=$(readlink ${DESTDIR}/$j)
				newlnk=$(basename $j)
				rm -f ${DESTDIR}/$j
				cd ${DESTDIR}/$dirat
				ln -s ${lnkat}.gz ${newlnk}.gz
				continue
			fi
			echo "=> Compressing info file: $j..."
			gzip -q9 ${DESTDIR}/$j
		done
	fi

	#
	# Find out if this package contains manual pages and
	# compress all them with gzip.
	#
	if [ -d "${DESTDIR}/usr/share/man" ]; then
		for f in $(find -L ${DESTDIR}/usr/share/man -type f); do
			j=$(echo $f|sed -e "$fpattern")
			[ "$j" = "" ] && continue
			if $(echo $j|grep -q '.*.gz$'); then
				continue
			fi
			if [ -h ${DESTDIR}/$j ]; then
				dirat=$(dirname $j)
				lnkat=$(readlink ${DESTDIR}/$j)
				newlnk=$(basename $j)
				rm -f ${DESTDIR}/$j
				cd ${DESTDIR}/$dirat
				ln -s ${lnkat}.gz ${newlnk}.gz
				continue
			fi
			echo "=> Compressing manpage: $j..."
			gzip -q9 ${DESTDIR}/$j
		done
	fi

	cd ${DESTDIR}
	msg_normal "Writing package metadata for $pkgname-$lver..."

	write_metadata_flist_header $TMPFPLIST

	# Pass 1: add links.
	for f in $(find ${DESTDIR} -type l); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "<key>type</key>" >> $TMPFPLIST
		echo "<string>link</string>" >> $TMPFPLIST
		echo "</dict>" >> $TMPFPLIST
	done

	# Pass 2: add regular files.
	for f in $(find ${DESTDIR} -type f); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "<key>type</key>" >> $TMPFPLIST
		echo "<string>file</string>" >> $TMPFPLIST
		echo "<key>sha256</key>" >> $TMPFPLIST
		echo "<string>$(xbps-digest $f)</string>"  >> $TMPFPLIST
		for i in ${conf_files}; do
			if [ "$j" = "$i" ]; then
				echo "<key>conf_file</key>"  >> $TMPFPLIST
				echo "<true/>" >> $TMPFPLIST
				break
			fi
		done
		echo "</dict>" >> $TMPFPLIST
	done

	# Pass 3: add directories.
	for f in $(find ${DESTDIR} -type d|sort -ur); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "<key>type</key>" >> $TMPFPLIST
		echo "<string>dir</string>" >> $TMPFPLIST
		for i in ${keep_dirs}; do
			if [ "$j" = "$i" ]; then
				echo "<key>keep</key>" >> $TMPFPLIST
				echo "<true/>" >> $TMPFPLIST
				break
			fi
		done
		echo "</dict>" >> $TMPFPLIST
	done
	echo "</array>" >> $TMPFPLIST
	echo "</dict>" >> $TMPFPLIST
	echo "</plist>" >> $TMPFPLIST
	sed -i -e /^$/d $TMPFLIST

	#
	# Find out if this package contains info files and write
	# a list will all them in a file.
	#
	if [ -d "${DESTDIR}/usr/share/info" ]; then
		for f in $(find ${DESTDIR}/usr/share/info -type f); do
			j=$(echo $f|sed -e "$fpattern")
			[ "$j" = "" ] && continue
			echo "$j" >> $TMPINFOLIST
		done
	fi

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
<string>$lver</string>
<key>architecture</key>
<string>$arch</string>
<key>installed_size</key>
<integer>$(du -sb ${DESTDIR}|awk '{print $1}')</integer>
<key>maintainer</key>
<string>$(echo $maintainer|sed -e 's|<|[|g;s|>|]|g')</string>
<key>short_desc</key>
<string>$short_desc</string>
<key>long_desc</key>
<string>$long_desc</string>
_EOF
	# Dependencies
	if [ -n "$run_depends" ]; then
		echo "<key>run_depends</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${run_depends}; do
			echo "<string>$f</string>" >> $TMPFPROPS
		done
		echo "</array>" >> $TMPFPROPS
	fi

	# Configuration files
	if [ -n "$conf_files" ]; then
		echo "<key>conf_files</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${conf_files}; do
			echo "<string>$f</string>" >> $TMPFPROPS
		done
		echo "</array>" >> $TMPFPROPS
	fi
	# Keep directories while removing.
	if [ -n "$keep_dirs" ]; then
		echo "<key>keep_dirs</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${keep_dirs}; do
			echo "<string>$f</string>" >> $TMPFPROPS
		done
		echo "</array>" >> $TMPFPROPS
	fi

	# Terminate the property list file.
	echo "</dict>" >> $TMPFPROPS
	echo "</plist>" >> $TMPFPROPS

	if [ ! -d $metadir ]; then
		mkdir -p $metadir >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "ERROR: you don't have enough perms for this."
			rm -f $TMPFLIST $TMPFPROPS
			exit 1
		fi
	fi

	# Write metadata files and cleanup.
	if [ -s $TMPFLIST ]; then
		mv -f $TMPFLIST $metadir/flist
	else
		rm -f $TMPFLIST
	fi
	mv -f $TMPFPLIST $metadir/files.plist
	mv -f $TMPFPROPS $metadir/props.plist
	if [ -s $TMPINFOLIST ]; then
		mv -f $TMPINFOLIST $metadir/info-files
	else
		rm -f $TMPINFOLIST
	fi

	# Register the shells into /etc/shells if requested.
	if [ -n "${register_shell}" ]; then
		triggers="$triggers register-shell"
		for f in ${register_shell}; do
			echo $f >> $metadir/shells
		done
	fi

	$XBPS_REGPKGDB_CMD sanitize-plist $metadir/files.plist
	$XBPS_REGPKGDB_CMD sanitize-plist $metadir/props.plist
	chmod 644 $metadir/*

	#
	# Update desktop-file-utils database if package contains
	# any desktop file in /usr/share/applications.
	#
	if [ -d ${DESTDIR}/usr/share/applications ]; then
		if find . -type f -name \*.desktop 2>&1 >/dev/null; then
			triggers="$triggers update-desktopdb"
		fi
	fi

	#
	# Create the INSTALL/REMOVE scripts if package uses them
	# or uses any available trigger.
	#
	. ${XBPS_SHUTILSDIR}/metadata_scripts.sh
	xbps_write_metadata_scripts_pkg install
	xbps_write_metadata_scripts_pkg remove
}
