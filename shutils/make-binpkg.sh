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
