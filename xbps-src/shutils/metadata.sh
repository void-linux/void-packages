#-
# Copyright (c) 2008-2011 Juan Romero Pardines.
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
		if [ $? -eq 0 -a -z "$DESTDIR_ONLY_INSTALL" ]; then
			continue
		fi

		if [ ! -f $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find subpkg '${subpkg}' build template!\n"
		fi
		setup_tmpl ${sourcepkg}
		unset run_depends conf_files noarch triggers replaces \
			revision system_accounts system_groups \
			preserve xml_entries sgml_entries \
			xml_catalogs sgml_catalogs gconf_entries gconf_schemas \
			gtk_iconcache_dirs font_dirs dkms_modules provides \
			kernel_hooks_version conflicts pycompile_dirs \
			pycompile_module systemd_services make_dirs
		. $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template
		pkgname=${subpkg}
		set_tmpl_common_vars
		verify_rundeps ${DESTDIR}
		xbps_write_metadata_pkg_real
	done

	if [ -n "$build_style" -a "$build_style" = "meta-template" -a -z "${run_depends}" ]; then
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
	# Verify pkg deps.
	verify_rundeps ${DESTDIR}
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
		msg_error "$pkgname not installed into destdir.\n"
	fi

	if [ -n "$noarch" ]; then
		arch=noarch
	else
		arch=$XBPS_MACHINE
	fi

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	#
	# If package provides virtual packages, create dynamically the
	# required virtualpkg.d files.
	#
	if [ -n "$provides" -a -n "$replaces" ]; then
		_tmpf=$(mktemp) || msg_error "$pkgver: failed to create tempfile.\n"
		cat > ${_tmpf} <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>virtual-pkgver</key>
	<string>$provides</string>
	<key>target-pkgpattern</key>
	<string>$(echo $replaces|sed "s|<|\&lt;|g;s|>|\&gt;|g")</string>
</dict>
</plist>
_EOF
		install -Dm644 ${_tmpf} \
			${DESTDIR}/etc/xbps/virtualpkg.d/${pkgname}.plist
		vmkdir etc/xbps/virtualpkg.d.wants && curcwd=$(pwd) && \
			cd ${DESTDIR}/etc/xbps/virtualpkg.d.wants && \
			ln -sf ../virtualpkg.d/${pkgname}.plist . && \
			cd ${curcwd} && rm -f ${_tmpf} || \
			msg_error "$pkgver: failed to create virtualpkg.d file in DESTDIR!\n"
	fi

        #
        # Find out if this package contains info files and compress
        # all them with gzip.
        #
	if [ -f ${DESTDIR}/usr/share/info/dir ]; then
		# Always remove this file if curpkg is not texinfo.
		if [ "$pkgname" != "texinfo" ]; then
			[ -f ${DESTDIR}/usr/share/info/dir ] && \
				rm -f ${DESTDIR}/usr/share/info/dir
		fi
		# Add info-files trigger.
		triggers="info-files $triggers"
		msg_normal "$pkgver: processing info(1) files...\n"

		find ${DESTDIR}/usr/share/info -type f -follow | while read f
		do
			j=$(echo "$f"|sed -e "$fpattern")
			[ "$j" = "" ] && continue
			[ "$j" = "/usr/share/info/dir" ] && continue
			# Ignore compressed files.
			if $(echo "$j"|grep -q '.*.gz$'); then
				continue
			fi
			# Ignore non info files.
			if ! $(echo "$j"|grep -q '.*.info$') && \
			   ! $(echo "$j"|grep -q '.*.info-[0-9]*$'); then
				continue
			fi
			if [ -h ${DESTDIR}/"$j" ]; then
				dirat=$(dirname "$j")
				lnkat=$(readlink ${DESTDIR}/"$j")
				newlnk=$(basename "$j")
				rm -f ${DESTDIR}/"$j"
				cd ${DESTDIR}/"$dirat"
				ln -s "${lnkat}".gz "${newlnk}".gz
				continue
			fi
			echo "   Compressing info file: $j..."
			gzip -q9 ${DESTDIR}/"$j"
		done
	fi

	#
	# Find out if this package contains manual pages and
	# compress all them with gzip.
	#
	if [ -d "${DESTDIR}/usr/share/man" ]; then
		msg_normal "$pkgver: processing manual pages...\n"
		find ${DESTDIR}/usr/share/man -type f -follow | while read f
		do
			j=$(echo "$f"|sed -e "$fpattern")
			[ "$j" = "" ] && continue
			if $(echo "$j"|grep -q '.*.gz$'); then
				continue
			fi
			if [ -h ${DESTDIR}/"$j" ]; then
				dirat=$(dirname "$j")
				lnkat=$(readlink ${DESTDIR}/"$j")
				newlnk=$(basename "$j")
				rm -f ${DESTDIR}/"$j"
				cd ${DESTDIR}/"$dirat"
				ln -s "${lnkat}".gz "${newlnk}".gz
				continue
			fi
			echo "   Compressing manpage: $j..."
			gzip -q9 ${DESTDIR}/"$j"
		done
	fi

	# Write the files.plist file.
	TMPFLIST=$(mktemp -t flist.XXXXXXXXXX) || exit 1
	TMPFPLIST=$(mktemp -t fplist.XXXXXXXXXX) || exit 1

	msg_normal "$pkgver: creating package metadata...\n"

	cat > "$TMPFPLIST" <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
_EOF
	# Pass 1: add links.
	echo "<key>links</key>" >> $TMPFPLIST
	echo "<array>" >> $TMPFPLIST
	find ${DESTDIR} -type l | while read f
	do
		j=$(echo "$f"|sed -e "$fpattern")
		[ "$j" = "" ] && continue
		echo "$j" >> $TMPFLIST
		echo "<dict>" >> $TMPFPLIST
		echo "<key>file</key>" >> $TMPFPLIST
		echo "<string>$j</string>" >> $TMPFPLIST
		echo "<key>target</key>" >> $TMPFPLIST
		lnk=$(readlink -f "$f"|sed -e "s|${DESTDIR}||")
		if [ -z "$lnk" -o "$lnk" = "" ]; then
			lnk=$(readlink "$f"|sed -e "s|${DESTDIR}||")
		fi
		echo "<string>$lnk</string>" >> $TMPFPLIST
		echo "</dict>" >> $TMPFPLIST
	done
	echo "</array>" >> $TMPFPLIST

	# Pass 2: add regular files.
	echo "<key>files</key>" >> $TMPFPLIST
	echo "<array>" >> $TMPFPLIST
	find ${DESTDIR} -type f | while read f
	do
		j=$(echo "$f"|sed -e "$fpattern")
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
		echo "<string>$(${XBPS_DIGEST_CMD} "$f")</string>"  \
			>> $TMPFPLIST
		echo "</dict>" >> $TMPFPLIST
	done
	echo "</array>" >> $TMPFPLIST

	# Pass 3: add directories.
	echo "<key>dirs</key>" >> $TMPFPLIST
	echo "<array>" >> $TMPFPLIST
	find ${DESTDIR} -type d|sort -ur | while read f
	do
		j=$(echo "$f"|sed -e "$fpattern")
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
			i=${DESTDIR}/"${f}"
			[ ! -f "${i}" ] && continue
			echo "<dict>" >> $TMPFPLIST
			echo "<key>file</key>" >> $TMPFPLIST
			echo "<string>$f</string>" >> $TMPFPLIST
			echo "<key>sha256</key>" >> $TMPFPLIST
			echo "<string>$(${XBPS_DIGEST_CMD} "${i}")</string>" \
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
<string>$pkgver</string>
<key>architecture</key>
<string>$arch</string>
<key>installed_size</key>
<integer>$(($instsize * 1024))</integer>
<key>maintainer</key>
<string>$(echo $maintainer|sed -e 's|<|\&lt;|g;s|>|\&gt;|g')</string>
<key>short_desc</key>
<string>$short_desc</string>
<key>long_desc</key>
<string>$long_desc</string>
<key>packaged-with</key>
<string>xbps-src $XBPS_SRC_BUILD_VERSION</string>
_EOF
	#
	# If package sets $dkms_modules, add dkms rundep.
	#
	if [ -n "$dkms_modules" ]; then
		Add_dependency run dkms
	fi

	#
	# If package sets $system_accounts or $system_groups, add shadow rundep.
	#
	if [ -n "$system_accounts" -o -n "$system_groups" ]; then
		Add_dependency run shadow
	fi

	# pkg needs to preserve its files after removal/upgrade?
	if [ -n "$preserve" ]; then
		echo "<key>preserve</key>" >> $TMPFPROPS
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
			echo "<string>$(echo $f|sed "s|<|\&lt;|g;s|>|\&gt;|g")</string>" >> $TMPFPROPS
		done
		echo "</array>" >> $TMPFPROPS
	fi

	# Conflicting package(s).
	if [ -n "$conflicts" ]; then
		echo "<key>conflicts</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${conflicts}; do
			echo "<string>$(echo $f|sed "s|<|\&lt;|g;s|>|\&gt;|g")</string>" >> $TMPFPROPS
		done
		echo "</array>" >> $TMPFPROPS
	fi

	# Provides virtual package(s).
	if [ -n "$provides" ]; then
		echo "<key>provides</key>" >> $TMPFPROPS
		echo "<array>" >> $TMPFPROPS
		for f in ${provides}; do
			echo "<string>$(echo $f|sed "s|<|\&lt;|g;s|>|\&gt;|g")</string>" >> $TMPFPROPS
		done
		echo "</array>" >> $TMPFPROPS
	fi

	# Build date.
	echo "<key>build_date</key>" >> $TMPFPROPS
	echo "<string>$(LANG=C date -u "+%A %d %B, %Y, %T UTC")</string>" >> $TMPFPROPS

	# Homepage
	if [ -n "$homepage" ]; then
		echo "<key>homepage</key>" >> $TMPFPROPS
		echo "<string>$homepage</string>" >> $TMPFPROPS
	fi

	# License
	if [ -n "$license" ]; then
		echo "<key>license</key>" >> $TMPFPROPS
		echo "<string>$license</string>" >> $TMPFPROPS
	fi

	# Terminate the property list file.
	echo "</dict>" >> $TMPFPROPS
	echo "</plist>" >> $TMPFPROPS

	if [ ! -d $metadir ]; then
		mkdir -m0755 -p $metadir >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			msg_red "you don't have enough perms for this!\n"
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

	$XBPS_PKGDB_CMD sanitize-plist ${DESTDIR}/files.plist || \
		msg_error "$pkgname: failed to externalize files.plist!\n"
	$XBPS_PKGDB_CMD sanitize-plist ${DESTDIR}/props.plist || \
		msg_error "$pkgname: failed to externalize props.plist!\n"

	chmod 644 ${DESTDIR}/files.plist ${DESTDIR}/props.plist
	[ -f $metadir/flist ] && chmod 644 $metadir/flist

	#
	# Create the INSTALL/REMOVE scripts if package uses them
	# or uses any available trigger.
	#
	local meta_install meta_remove
	if [ -n "${sourcepkg}" -a "${sourcepkg}" != "${pkgname}" ]; then
		meta_install=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.INSTALL
		meta_remove=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.REMOVE
	else
		meta_install=${XBPS_SRCPKGDIR}/${pkgname}/INSTALL
		meta_remove=${XBPS_SRCPKGDIR}/${pkgname}/REMOVE
	fi
	xbps_write_metadata_scripts_pkg install ${meta_install} || \
		msg_error "$pkgname: failed to write INSTALL metadata file!\n"

	xbps_write_metadata_scripts_pkg remove ${meta_remove} || \
		msg_error "$pkgname: failed to write REMOVE metadata file!\n"

	msg_normal "$pkgver: successfully created package metadata.\n"
}
