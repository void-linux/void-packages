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

. ${XBPS_SHUTILSDIR}/tmpl_funcs.sh

#
# Installs a pkg by reading its build template file.
#
install_pkg()
{
	local pkg=
	local curpkgn="$1"
	local cdestdir=
	local cur_tmpl="$XBPS_TEMPLATESDIR/$curpkgn/template"

	if [ -z $cur_tmpl -o ! -f $cur_tmpl ]; then
		msg_error "cannot find $cur_tmpl template build file."
	fi

	#
	# If we are being invoked through the chroot, re-read config file
	# to get correct stuff.
	#
	if [ -n "$in_chroot" ]; then
		check_config_vars
		set_defvars
	fi

	. $XBPS_SHUTILSDIR/tmpl_funcs.sh
	reset_tmpl_vars
	. $cur_tmpl
	pkg="$curpkgn-$version"

	#
	# If we are the originator package save the path this template in
	# other var for future use.
	#
	[ -z "$origin_tmpl" ] && origin_tmpl=$pkgname

	if [ -z "$base_chroot" -a -z "$in_chroot" ]; then
		. $XBPS_SHUTILSDIR/chroot.sh
		[ -n "$install_destdir_target" ] && cdestdir=yes
		xbps_chroot_handler install $curpkgn $cdestdir
		return $?
	fi

	#
	# We are going to install a new package.
	#
	setup_tmpl $curpkgn

	#
	# Install dependencies required by this package.
	#
	if [ -z "$doing_deps" ]; then
		. $XBPS_SHUTILSDIR/builddep_funcs.sh
		install_dependencies_pkg $pkg
		#
		# At this point all required deps are installed, and
		# only remaining is the origin template; install it.
		#
		unset doing_deps
		reset_tmpl_vars
		setup_tmpl $curpkgn
	fi

	#
	# Fetch, extract, build and install into the destination directory.
	#
	. $XBPS_SHUTILSDIR/fetch_funcs.sh
	fetch_distfiles

	if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
		. $XBPS_SHUTILSDIR/extract_funcs.sh
		extract_distfiles
	fi

	if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
		. $XBPS_SHUTILSDIR/configure_funcs.sh
		configure_src_phase
	fi

	if [ ! -f "$XBPS_BUILD_DONE" ]; then
		. $XBPS_SHUTILSDIR/build_funcs.sh
		build_src_phase
	fi

	. $XBPS_SHUTILSDIR/install_funcs.sh
	install_src_phase $curpkgn

	# Always write metadata to package's destdir.
	. $XBPS_SHUTILSDIR/metadata.sh
	xbps_write_metadata_pkg $curpkgn

	#
	# Do not stow package if it wasn't requested.
	#
	if [ -z "$install_destdir_target" ]; then
		. $XBPS_SHUTILSDIR/stow_funcs.sh
		stow_pkg $curpkgn
	fi
}

#
# Lists files installed by a package.
#
list_pkg_files()
{
	local pkg="$1"
	local ver=

	[ -z $pkg ] && msg_error "unexistent package, aborting."

	ver=$($XBPS_REGPKGDB_CMD version $pkg)
	[ -z "$ver" ] && msg_error "$pkg is not installed."

	cat $XBPS_PKGMETADIR/$pkg/flist
}

#
# Removes a currently installed package (unstow + removed from destdir).
#
remove_pkg()
{
	local pkg="$1" subpkg ver

	[ -z $pkg ] && msg_error "unexistent package, aborting."

	if [ ! -f "$XBPS_TEMPLATESDIR/$pkg/template" ]; then
		msg_error "cannot find template build file."
	fi

	. $XBPS_TEMPLATESDIR/$pkg/template
	for f in ${subpackages}; do
		if [ "$pkg" = "${pkgname}-${f}" ]; then
			pkgname=${pkg}
			break;
		fi
	done

	ver=$($XBPS_REGPKGDB_CMD version $pkg)
	[ -z "$ver" ] && msg_error "$pkg is not installed."

	. $XBPS_SHUTILSDIR/stow_funcs.sh
	unstow_pkg $pkg
	if [ $? -eq 0 -a -d $XBPS_DESTDIR/$pkg-${ver%_${revision}} ]; then
		rm -rf $XBPS_DESTDIR/$pkg-${ver%_${revision}}
	fi
	return $?
}
