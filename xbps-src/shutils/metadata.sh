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
_EOF

}

xbps_write_metadata_pkg()
{
	local subpkg spkgrev

	for subpkg in ${subpackages}; do
		if [ -n "${revision}" ]; then
			spkgrev="${subpkg}-${version}_${revision}"
		else
			spkgrev="${subpkg}-${version}"
		fi
		check_installed_pkg ${spkgrev}
		[ $? -eq 0 ] && continue

		if [ ! -f $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find subpkg '${subpkg}' build template!"
		fi
		setup_tmpl ${sourcepkg}
		unset run_depends conf_files noarch triggers replaces \
			revision openrc_services essential keep_empty_dirs
		. $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template
		pkgname=${subpkg}
		set_tmpl_common_vars
		xbps_write_metadata_pkg_real
	done

	if [ "$build_style" = "meta-template" -a -z "${run_depends}" ]; then
		for spkg in ${subpackages}; do
			if [ -n "${revision}" ]; then
				spkgrev="${spkg}-${version}_$revision"
			else
				spkgrev="${spkg}-${version}"
			fi
			run_depends="${run_depends} ${spkgrev}"
		done
	fi
	setup_tmpl ${sourcepkg}
	xbps_write_metadata_pkg_real
}

#
# This function writes the metadata files into package's destdir,
# these will be used for binary packages.
#
xbps_write_metadata_pkg_real()
{
	local metadir=${DESTDIR}/var/db/xbps/metadata/$pkgname
	local f i j found arch dirat lnkat newlnk lver TMPFLIST TMPFPLIST
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
			# Ignore compressed files.
			if $(echo $j|grep -q '.*.gz$'); then
				continue
			fi
			# Ignore non info files.
			if ! $(echo $j|grep -q '.*.info$') && \
			   ! $(echo $j|grep -q '.*.info-[0-9]*$'); then
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
			echo "===> Compressing info file: $j..."
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
			echo "===> Compressing manpage: $j..."
			gzip -q9 ${DESTDIR}/$j
		done
	fi

	cd ${DESTDIR}
	msg_normal "Writing package metadata for $pkgname-$lver..."

	write_metadata_flist_header $TMPFPLIST

	# Pass 1: add links.
	echo "<key>links</key>" >> $TMPFPLIST
	echo "<array>" >> $TMPFPLIST
	for f in $(find ${DESTDIR} -type l); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "</dict>" >> $TMPFPLIST
	done
	echo "</array>" >> $TMPFPLIST

	# Pass 2: add regular files.
	echo "<key>files</key>" >> $TMPFPLIST
	echo "<array>" >> $TMPFPLIST
	for f in $(find ${DESTDIR} -type f); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		# Skip configuration files.
		for i in ${conf_files}; do
			[ "$j" = "$i" ] && found=1 && break
		done
		[ -n "$found" ] && unset found && continue
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "<key>sha256</key>" >> $TMPFPLIST
		echo "<string>$(${XBPS_DIGEST_CMD} $f)</string>"  \
			>> $TMPFPLIST
		echo "</dict>" >> $TMPFPLIST
	done
	echo "</array>" >> $TMPFPLIST

	# Pass 3: add directories.
	echo "<key>dirs</key>" >> $TMPFPLIST
	echo "<array>" >> $TMPFPLIST
	for f in $(find ${DESTDIR} -type d|sort -ur); do
		j=$(echo $f|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "</dict>" >> $TMPFPLIST
	done
	echo "</array>" >> $TMPFPLIST

	# Add configuration files into its own array.
	if [ -n "${conf_files}" ]; then
		echo "<key>conf_files</key>" >> $TMPFPLIST
		echo "<array>" >> $TMPFPLIST
		for f in ${conf_files}; do
			i=${DESTDIR}/${f}
			[ ! -f ${i} ] && continue
			echo "<dict>" >> $TMPFPLIST
			echo "<key>file</key>" >> $TMPFPLIST
			echo "<string>$f</string>" >> $TMPFPLIST
			echo "<key>sha256</key>" >> $TMPFPLIST
			echo "<string>$(${XBPS_DIGEST_CMD} ${i})</string>" \
				>> $TMPFPLIST
			echo "</dict>" >> $TMPFPLIST
		done
		echo "</array>" >> $TMPFPLIST
	fi

	echo "</dict>" >> $TMPFPLIST
	echo "</plist>" >> $TMPFPLIST
	sed -i -e /^$/d $TMPFLIST

	# Write the props.plist file.
	local TMPFPROPS=$(mktemp -t fprops.XXXXXXXXXX) || exit 1

	local instsize=$(du -sk ${DESTDIR}|awk '{print $1}')

	cat > $TMPFPROPS <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>pkgname</key>
<string>$pkgname</string>
<key>version</key>
<string>$lver</string>
<key>pkgver</key>
<string>$pkgname-$lver</string>
<key>architecture</key>
<string>$arch</string>
<key>installed_size</key>
<integer>$(($instsize * 1024))</integer>
<key>maintainer</key>
<string>$(echo $maintainer|sed -e 's|<|[|g;s|>|]|g')</string>
<key>short_desc</key>
<string>$short_desc</string>
<key>long_desc</key>
<string>$long_desc</string>
_EOF
	#
	# If package sets $openrc_services, add the openrc-service
	# trigger and OpenRC run dependency.
	#
	if [ -n "$openrc_services" ]; then
		triggers="$triggers openrc-service"
		Add_dependency run OpenRC
	fi

	# Is this an essential pkg?
	if [ -n "$essential" ]; then
		echo "<key>essential</key>" >> $TMPFPROPS
		echo "<true/>" >> $TMPFPROPS
	fi

	# Dependencies
	if [ -n "$run_depends" ]; then
		echo "<key>run_depends</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${run_depends}; do
			echo "<string>$(echo $f|sed "s|<|\&lt;|g;s|>|\&gt;|g")</string>" >> $TMPFPROPS
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

	# Replace package(s).
	if [ -n "$replaces" ]; then
		echo "<key>replaces</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${replaces}; do
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
	mv -f $TMPFPLIST ${DESTDIR}/files.plist
	mv -f $TMPFPROPS ${DESTDIR}/props.plist

	$XBPS_PKGDB_CMD sanitize-plist ${DESTDIR}/files.plist
	$XBPS_PKGDB_CMD sanitize-plist ${DESTDIR}/props.plist
	chmod 644 ${DESTDIR}/files.plist ${DESTDIR}/props.plist
	[ -f $metadir/flist ] && chmod 644 $metadir/flist

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
