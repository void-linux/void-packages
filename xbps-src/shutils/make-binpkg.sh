#-
# Copyright (c) 2008-2010 Juan Romero Pardines.
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
	local subpkg

	[ -z "$pkgname" ] && return 1

	for subpkg in ${subpackages}; do
		unset revision noarch
		. $XBPS_SRCPKGDIR/$pkgname/$subpkg.template
		pkgname=${subpkg}
		set_tmpl_common_vars
		xbps_make_binpkg_real
		setup_tmpl ${sourcepkg}
	done

	[ -n "${subpackages}" ] && set_tmpl_common_vars
	xbps_make_binpkg_real
	return $?
}

binpkg_cleanup()
{
	printf "\nInterrupted! removing $binpkg file!\n"
	rm -f $pkgdir/$binpkg
	exit 1
}

#
# This function builds a binary package from an installed xbps
# package in destdir.
#
xbps_make_binpkg_real()
{
	local mfiles binpkg pkgdir arch lver dirs _dirs d clevel

	if [ ! -d "${DESTDIR}" ]; then
		msg_warn "cannot find destdir for $pkgname... skipping!"
		return 0
	fi
	cd ${DESTDIR}

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
	binpkg=$pkgname-$lver.$arch.xbps
	pkgdir=$XBPS_PACKAGESDIR/$arch
	#
	# Don't overwrite existing binpkgs by default, skip them.
	#
	if [ -f $pkgdir/$binpkg ]; then
		echo "=> Skipping existing $binpkg pkg..."
		return 0
	fi

	#
	# Make sure that INSTALL is the first file on the archive,
	# this is to ensure that it's run before any other file is
	# unpacked.
	#
	if [ -x ./INSTALL -a -x ./REMOVE ]; then
		mfiles="./INSTALL ./REMOVE"
	elif [ -x ./INSTALL ]; then
		mfiles="./INSTALL"
	elif [ -x ./REMOVE ]; then
		mfiles="./REMOVE"
	fi
	mfiles="$mfiles ./files.plist ./props.plist"
	_dirs=$(find . -maxdepth 1 -type d -o -type l)
	for d in ${_dirs}; do
		[ "$d" = "." ] && continue
		dirs="$d $dirs"
	done

	[ -n "$XBPS_COMPRESS_LEVEL" ] && clevel="-$XBPS_COMPRESS_LEVEL"

	[ ! -d $pkgdir ] && mkdir -p $pkgdir

	# Remove binpkg if interrupted...
	trap "binpkg_cleanup" INT

	echo -n "=> Building $binpkg... "
	${fakeroot_cmd} ${fakeroot_cmd_args}			\
		tar --exclude "var/db/xbps/metadata/*/flist"	\
		-cpf - ${mfiles} ${dirs} |			\
		$XBPS_COMPRESS_CMD ${clevel} -qf > $pkgdir/$binpkg
	if [ $? -eq 0 ]; then
		echo "done."
	else
		rm -f $pkgdir/$binpkg
		echo "failed!"
	fi

	return $?
}
