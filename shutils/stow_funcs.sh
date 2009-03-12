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

stow_pkg()
{
	local pkg="$1"
	local automatic="$2"
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
		. $XBPS_TEMPLATESDIR/${sourcepkg}/${subpkg}.template
		pkgname=${sourcepkg}-${subpkg}
		set_tmpl_common_vars
		stow_pkg_real ${pkgname} ${automatic}
		run_template ${sourcepkg}
		if [ "${pkg}" = "${sourcepkg}-${subpkg}" ]; then
			#
			# If it's a subpackage, just remove sourcepkg from
			# destdir and return, we are done.
			#
			rm -rf $XBPS_DESTDIR/${sourcepkg}-${version}
			return $?
		fi
	done

	stow_pkg_real ${pkg} ${automatic}

	return $?
}

#
# Stow a package, i.e copy files from destdir into masterdir
# and register pkg into the package database.
#
stow_pkg_real()
{
	local pkg="$1"
	local automatic="$2"
	local i=

	[ -z "$pkg" ] && return 2

	if [ $(id -u) -ne 0 ] && [ ! -w $XBPS_MASTERDIR ]; then
		msg_error "cannot stow $pkg! (permission denied)"
	fi

	if [ "$build_style" = "meta-template" ]; then
		[ ! -d ${DESTDIR} ] && mkdir -p ${DESTDIR}
	fi

	[ -n "$stow_flag" ] && run_template $pkg

	cd ${DESTDIR} || exit 1

	# Copy files into masterdir.
	for i in $(echo *); do
		[ "$i" = "INSTALL" ] && continue
		cp -a ${i} $XBPS_MASTERDIR
	done

	#
	# Register pkg in plist file and add automatic installation
	# object if requested.
	#
	local regpkgdb_flags=
	if [ -n "$automatic" ]; then
		regpkgdb_flags="-a"
	fi
	$XBPS_REGPKGDB_CMD $regpkgdb_flags register \
		$pkg $version "$short_desc" || exit 1
}

#
# Unstow a package, i.e remove its files from masterdir and
# unregister pkg from package database.
#
unstow_pkg()
{
	local pkg="$1"
	local f=
	local ver=

	[ -z $pkg ] && msg_error "template wasn't specified?"

	if [ $(id -u) -ne 0 ] && \
	   [ ! -w $XBPS_MASTERDIR ]; then
		msg_error "cannot unstow $pkg! (permission denied)"
	fi

	run_template $pkg

	ver=$($XBPS_REGPKGDB_CMD version $pkg)
	if [ -z "$ver" ]; then
		msg_error "$pkg is not installed."
	fi

	cd $XBPS_PKGMETADIR/$pkg || exit 1
	if [ "$build_style" = "meta-template" ]; then
		# If it's a metapkg, do nothing.
		:
	elif [ ! -f flist ]; then
		msg_error "$pkg is incomplete, missing flist."
	elif [ ! -w flist ]; then
		msg_error "$pkg cannot be removed (permission denied)."
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
	rm -rf $XBPS_PKGMETADIR/$pkg

	# Unregister pkg from plist file.
	$XBPS_REGPKGDB_CMD unregister $pkg $ver

	return $?
}
