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

. ${XBPS_SHUTILSDIR}/builddep_funcs.sh

stow_pkg_handler()
{
	local action="$1" subpkg spkgrev

	for subpkg in ${subpackages}; do
		if [ -n "$revision" ]; then
			spkgrev="${subpkg}-${version}_${revision}"
		else
			spkgrev="${subpkg}-${version}"
		fi
		if [ "$action" = "stow" ]; then
			check_installed_pkg ${spkgrev}
			[ $? -eq 0 ] && continue
		fi
		if [ ! -f $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find $subpkg subpkg build template!"
		fi
		unset revision
		. $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template
		pkgname=${subpkg}
		set_tmpl_common_vars
		if [ "$action" = "stow" ]; then
			stow_pkg_real || return $?
		else
			unstow_pkg_real || return $?
		fi
		run_template ${sourcepkg}
	done

	if [ "$action" = "stow" ]; then
		stow_pkg_real
	else
		unstow_pkg_real
	fi
	return $?
}

#
# Stow a package, i.e copy files from destdir into masterdir
# and register pkg into the package database.
#
stow_pkg_real()
{
	local i lver regpkgdb_flags

	[ -z "$pkgname" ] && return 2

	if [ $(id -u) -ne 0 ] && [ ! -w $XBPS_MASTERDIR ]; then
		msg_error "cannot stow $pkgname! (permission denied)"
	fi

	if [ "$build_style" = "meta-template" ]; then
		[ ! -d ${DESTDIR} ] && mkdir -p ${DESTDIR}
	fi

	[ -n "$stow_flag" ] && run_template $pkgname

	cd ${DESTDIR} || exit 1

	# Copy files into masterdir.
	for i in $(echo *); do
		if [ "$i" = "INSTALL" -o "$i" = "REMOVE" -o \
		     "$i" = "files.plist" -o "$i" = "props.plist" ]; then
		     continue
		fi
		cp -a ${i} $XBPS_MASTERDIR
	done

	#
	# Register pkg in plist file.
	#
	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi
	$XBPS_PKGDB_CMD register $pkgname $lver "$short_desc"
	return $?
}

#
# Unstow a package, i.e remove its files from masterdir and
# unregister pkg from package database.
#
unstow_pkg_real()
{
	local f ver

	[ -z $pkgname ] && return 1

	if [ $(id -u) -ne 0 ] && \
	   [ ! -w $XBPS_MASTERDIR ]; then
		msg_error "cannot unstow $pkgname! (permission denied)"
	fi

	run_template $pkgname

	ver=$($XBPS_PKGDB_CMD version $pkgname)
	if [ -z "$ver" ]; then
		msg_error "$pkgname is not installed."
	fi

	cd $XBPS_PKGMETADIR/$pkgname || exit 1
	if [ "$build_style" = "meta-template" ]; then
		# If it's a metapkg, do nothing.
		:
	elif [ ! -f flist ]; then
		msg_error "$pkgname is incomplete, missing flist."
	elif [ ! -w flist ]; then
		msg_error "$pkgname cannot be removed (permission denied)."
	elif [ -s flist ]; then
		# Remove installed files.
		for f in $(cat flist); do
			if [ -f $XBPS_MASTERDIR/$f -o -h $XBPS_MASTERDIR/$f ]; then
				rm $XBPS_MASTERDIR/$f  >/dev/null 2>&1
				if [ $? -eq 0 ]; then
					echo "Removing file: $f"
				fi
			fi
		done

		for f in $(cat flist); do
			if [ -d $XBPS_MASTERDIR/$f ]; then
				rmdir $XBPS_MASTERDIR/$f >/dev/null 2>&1
				if [ $? -eq 0 ]; then
					echo "Removing directory: $f"
				fi
			fi
		done
	fi

	# Remove metadata dir.
	rm -rf $XBPS_PKGMETADIR/$pkgname

	# Unregister pkg from plist file.
	$XBPS_PKGDB_CMD unregister $pkgname $ver
	return $?
}
