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
	local subpkg

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
		unset run_depends conf_files keep_dirs noarch install_priority \
			triggers
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
			run_depends="$run_depends ${sourcepkg}-${subpkg}-${version}"
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
	local f i j arch dirat lnkat newlnk prioinst TMPFLIST TMPFPLIST
	local fpattern="s|${DESTDIR}||g;s|^\./$||g;/^$/d"

	if [ ! -d "${DESTDIR}" ]; then
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
	TMPINFOLIST=$(mktemp -t infolist.XXXXXXXXXX) || exit 1

        #
        # Find out if this package contains info files and compress
        # all them with gzip.
        #
	if [ -d "${DESTDIR}/usr/share/info" ]; then
		if [ -f ${XBPS_MASTERDIR}/usr/share/info/dir ]; then
			rm -f ${DESTDIR}/usr/share/info/dir
		fi
		# Add info-files trigger.
		triggers="info-files $triggers"

		for f in $(find -L ${DESTDIR}/usr/share/info -type f); do
			j=$(echo $f|sed -e "$fpattern")
			[ "$j" = "" ] && continue
			[ "$j" = "/usr/share/info/dir" ] && continue
			if $(echo $j|grep -q '.gz'); then
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
			if $(echo $j|grep -q '.gz'); then
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
	msg_normal "Writing package metadata for $pkgname-$version..."

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
<string>$version</string>
<key>architecture</key>
<string>$arch</string>
<key>priority</key>
<integer>$prioinst</integer>
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
	$XBPS_REGPKGDB_CMD sanitize-plist $metadir/files.plist
	$XBPS_REGPKGDB_CMD sanitize-plist $metadir/props.plist
	chmod 644 $metadir/*

	#
	# Create the INSTALL/REMOVE scripts if package uses them
	# or uses any available trigger.
	#
	xbps_make_script install
	xbps_make_script remove
}

xbps_make_script()
{
	local action="$1"
	local metadir="${DESTDIR}/var/db/xbps/metadata/$pkgname"
	local tmpf=$(mktemp -t xbps-install.XXXXXXXXXX) || exit 1
	local triggerdir="./var/db/xbps/triggers"
	local targets found

	case "$action" in
		install) ;;
		remove) ;;
		*) return 1;;
	esac

	cd ${DESTDIR}
	cat >> $tmpf <<_EOF
#!/bin/sh -e
#
# Generic INSTALL/REMOVE script.
#
# $1 = cwd
# $2 = action
# $3 = pkgname
# $4 = version
#
# Note that paths must be relative to CWD, to avoid calling
# host commands.
#

export PATH="./bin:./sbin:./usr/bin:./usr/sbin"
_EOF

	if [ -n "$triggers" ]; then
		found=1
		echo "case \"\$2\" in" >> $tmpf
		echo "pre)" >> $tmpf
		for f in ${triggers}; do
			if [ ! -f $XBPS_TRIGGERSDIR/$f ]; then
				rm -f $tmpf
				msg_error "$pkgname: unknown trigger $f, aborting!"
			fi
		done
		for f in ${triggers}; do
			targets=$($XBPS_TRIGGERSDIR/$f targets)
			for j in ${targets}; do
				if ! $(echo $j|grep -q pre-${action}); then
					continue
				fi
				printf "\t$triggerdir/$f run $j $pkgname $version\n" >> $tmpf
				printf "\t[ \$? -ne 0 ] && exit \$?\n" >> $tmpf
			done
		done
		printf "\t;;\n" >> $tmpf
		echo "post)" >> $tmpf
		for f in ${triggers}; do
			targets=$($XBPS_TRIGGERSDIR/$f targets)
			for j in ${targets}; do
				if ! $(echo $j|grep -q post-${action}); then
					continue
				fi
				printf "\t$triggerdir/$f run $j $pkgname $version\n" >> $tmpf
				printf "\t[ \$? -ne 0 ] && exit \$?\n" >> $tmpf
			done
		done
		printf "\t;;\n" >> $tmpf
		echo "esac" >> $tmpf
		echo >> $tmpf
	fi

	case "$action" in
	install)
		if [ -f "$XBPS_TEMPLATESDIR/$pkgname/INSTALL" ]; then
			found=1
			cat $XBPS_TEMPLATESDIR/$pkgname/INSTALL >> $tmpf
		fi
		echo "exit 0" >> $tmpf
		if [ -z "$found" ]; then
			rm -f $tmpf
			return 0
		fi
		mv $tmpf ${DESTDIR}/INSTALL && chmod 755 ${DESTDIR}/INSTALL
		;;
	remove)
		if [ -f "$XBPS_TEMPLATESDIR/$pkgname/REMOVE" ]; then
			found=1
			cat $XBPS_TEMPLATESDIR/$pkgname/REMOVE >> $tmpf
		fi
		echo "exit 0" >> $tmpf
		if [ -z "$found" ]; then
			rm -f $tmpf
			return 0
		fi
		mv $tmpf ${metadir}/REMOVE && chmod 755 ${metadir}/REMOVE
		;;
	esac
}

xbps_make_binpkg()
{
	local pkg="$1"
	local subpkg

	for subpkg in ${subpackages}; do
		if [ "$pkg" = "$pkgname-$subpkg" ]; then
			. $XBPS_TEMPLATESDIR/$pkgname/$subpkg.template
			pkgname=${sourcepkg}-${subpkg}
			set_tmpl_common_vars
			xbps_make_binpkg_real
			return $?
		fi
		run_template ${sourcepkg}
	done

	set_tmpl_common_vars
	xbps_make_binpkg_real
	return $?
}

#
# This function builds a binary package from an installed xbps
# package in destdir.
#
xbps_make_binpkg_real()
{
	local binpkg pkgdir arch use_sudo

	if [ ! -d ${DESTDIR} ]; then
		echo "$pkgname: unexistent destdir... skipping!"
		return 0
	fi

	cd ${DESTDIR}

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
			--exclude "./INSTALL" \
			--exclude "./var/db/xbps/metadata/*/flist" && \
			bzip2 -9 $XBPS_DESTDIR/$binpkg && \
			mv $XBPS_DESTDIR/$binpkg.bz2 $XBPS_DESTDIR/$binpkg
	else
		run_rootcmd $use_sudo tar cfp $XBPS_DESTDIR/$binpkg . \
			--exclude "./var/db/xbps/metadata/*/flist" && \
			bzip2 -9 $XBPS_DESTDIR/$binpkg && \
			mv $XBPS_DESTDIR/$binpkg.bz2 $XBPS_DESTDIR/$binpkg
	fi
	if [ $? -eq 0 ]; then
		[ ! -d $pkgdir ] && mkdir -p $pkgdir
		mv -f $XBPS_DESTDIR/$binpkg $pkgdir
		echo "=> Built package: $binpkg"
	fi

	return $?
}
