#!/bin/sh
#
# xbps - A simple, minimal, fast and uncomplete build package system.
#-
# Copyright (c) 2008 Juan Romero Pardines.
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
trap "echo && exit 1" INT QUIT

: ${XBPS_CONFIG_FILE:=@@XBPS_INSTALL_ETCDIR@@/xbps.conf}

: ${progname:=$(basename $0)}
: ${fakeroot_cmd:=fakeroot}
: ${fetch_cmd:=wget}
: ${xbps_machine:=$(uname -m)}

usage()
{
	cat << _EOF
$progname: [-C] [-c <config_file>] <target> <pkg>

Targets:
 build <pkg>            Build a package (fetch + extract + configure + build).
 build-pkg [<pkg>|all]  Build a binary package from <pkg>.
                        Package must be installed into destdir. If the <all>
                        keyword is used instead of <pkg>, all packages
                        currently installed will be used.
 chroot                 Enter to the chroot in masterdir.
 configure <pkg>        Configure a package (fetch + extract + configure).
 extract <pkg>          Extract distribution file(s) into build directory.
 fetch <pkg>            Download distribution file(s).
 genindex [/path/dir]   Generate a package index for a directory containing
                        binary packages. If no path is specified, the
                        XBPS_PACKAGESDIR in the configuration file will be
                        used by default.
 info <pkg>             Show information about <pkg>.
 install-destdir <pkg>  build + install into destdir.
 install <pkg>          install-destdir + stow.
 list                   List installed packages in masterdir.
 listfiles <pkg>        List installed files from <pkg>.
 remove	<pkg>           Remove package completely (destdir + masterdir).
 stow <pkg>             Copy <pkg> files from destdir into masterdir and
                        register package in database.
 unstow	<pkg>           Remove <pkg> files from masterdir and unregister
                        package from database.

Options:
 -C     Do not remove build directory after successful installation.
 -c     Path to global configuration file:
        if not specified @@XBPS_INSTALL_ETCDIR@@/xbps.conf is used.
_EOF
	exit 1
}

check_path()
{
	eval local orig="$1"

	case "$orig" in
		/) ;;
		/*) orig="${orig%/}" ;;
		*) orig="$(pwd)/${orig%/}" ;;
	esac

	path_fixed="$orig"
}

run_file()
{
	local file="$1"

	check_path "$file"
	. $path_fixed
}

set_defvars()
{
	local i=

	: ${XBPS_TEMPLATESDIR:=$XBPS_DISTRIBUTIONDIR/templates}
	: ${XBPS_HELPERSDIR:=$XBPS_TEMPLATESDIR/helpers}
	: ${XBPS_CACHEDIR:=$XBPS_MASTERDIR/var/cache/xbps}
	: ${XBPS_META_PATH:=$XBPS_CACHEDIR/}
	: ${XBPS_PKGMETADIR:=$XBPS_CACHEDIR/metadata}
	: ${XBPS_SHUTILSDIR:=$XBPS_DISTRIBUTIONDIR/shutils}

	local DDIRS="XBPS_TEMPLATESDIR XBPS_HELPERSDIR XBPS_SHUTILSDIR"
	for i in ${DDIRS}; do
		eval val="\$$i"
		[ ! -d "$val" ] &&  msg_error "cannot find $i, aborting."
	done

	XBPS_REGPKGDB_CMD="xbps-pkgdb -r $XBPS_MASTERDIR"
	XBPS_BIN_CMD="xbps-bin -r $XBPS_MASTERDIR"
}

#
# Checks that all required variables specified in the configuration
# file are properly working.
#
check_config_vars()
{
	local cffound=
	local f=

	if [ -z "$config_file_specified" ]; then
		config_file_paths="$XBPS_CONFIG_FILE ./etc/xbps.conf"
		for f in $config_file_paths; do
			[ -f $f ] && XBPS_CONFIG_FILE=$f && \
				cffound=yes && break
		done
		[ -z "$cffound" ] && msg_error "cannot find a config file"
	fi

	run_file ${XBPS_CONFIG_FILE}
	XBPS_CONFIG_FILE=$path_fixed

	if [ ! -f "$XBPS_CONFIG_FILE" ]; then
		msg_error "cannot find configuration file: $XBPS_CONFIG_FILE"
	fi

	local XBPS_VARS="XBPS_MASTERDIR XBPS_DESTDIR XBPS_BUILDDIR \
			 XBPS_SRCDISTDIR"

	for f in ${XBPS_VARS}; do
		eval val="\$$f"
		[ -z "$val" ] && msg_error "'$f' not set in configuration file"

		if [ ! -d "$val" ]; then
			mkdir "$val"
			[ $? -ne 0 ] && msg_error "couldn't create '$f' directory"
		fi
	done

	export PATH="$PATH:@@XBPS_INSTALL_PREFIX@@/sbin"
}

#
# main()
#
while getopts "Cc:" opt; do
	case $opt in
		C) dontrm_builddir=yes;;
		c) config_file_specified=yes; XBPS_CONFIG_FILE="$OPTARG";;
		--) shift; break;;
	esac
done
shift $(($OPTIND - 1))

[ $# -eq 0 -o $# -gt 2 ] && usage

target="$1"
if [ -z "$target" ]; then
	echo "=> ERROR: missing target."
	usage
fi

#
# Check configuration vars before anyting else, and set defaults vars.
#
check_config_vars
set_defvars
. $XBPS_SHUTILSDIR/common_funcs.sh

# Main switch
case "$target" in
build|configure)
	. $XBPS_SHUTILSDIR/tmpl_funcs.sh
	setup_tmpl $2

	if [ -z "$base_chroot" -a -z "$in_chroot" ]; then
		. $XBPS_SHUTILSDIR/chroot.sh
		if [ "$target" = "build" ]; then
			xbps_chroot_handler build $2
		else
			xbps_chroot_handler configure $2
		fi
	else
		. $XBPS_SHUTILSDIR/fetch_funcs.sh
		fetch_distfiles $2
		if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
			. $XBPS_SHUTILSDIR/extract_funcs.sh
			extract_distfiles $2
		fi
		if [ "$target" = "configure" ]; then
			. $XBPS_SHUTILSDIR/configure_funcs.sh
			configure_src_phase $2
		else
			if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
				. $XBPS_SHUTILSDIR/configure_funcs.sh
				configure_src_phase $2
			fi
			. $XBPS_SHUTILSDIR/build_funcs.sh
			build_src_phase $2
		fi
	fi
	;;
build-pkg)
	. $XBPS_SHUTILSDIR/binpkg.sh
	. $XBPS_SHUTILSDIR/tmpl_funcs.sh
	if [ "$2" = "all" ]; then
		for f in $($XBPS_BIN_CMD list|awk '{print $1}'); do
			setup_tmpl $f
			xbps_make_binpkg
			reset_tmpl_vars
		done
	else
		setup_tmpl $2
		xbps_make_binpkg
	fi
	;;
chroot)
	. $XBPS_SHUTILSDIR/chroot.sh
	xbps_chroot_handler chroot dummy
	;;
extract|fetch|info)
	. $XBPS_SHUTILSDIR/tmpl_funcs.sh
	setup_tmpl $2
	if [ "$target" = "info" ]; then
		. $XBPS_SHUTILSDIR/tmpl_funcs.sh
		info_tmpl $2
		exit $?
	fi
	if [ "$target" = "fetch" ]; then
		. $XBPS_SHUTILSDIR/fetch_funcs.sh
		fetch_distfiles $2
		exit $?
	fi
	. $XBPS_SHUTILSDIR/extract_funcs.sh
	extract_distfiles $2
	;;
genindex)
	. $XBPS_SHUTILSDIR/binpkg-genindex.sh
	write_repo_pkgindex $2
	;;
install|install-destdir)
	[ -z "$2" ] && msg_error "missing package name after target."
	[ "$target" = "install-destdir" ] && install_destdir_target=yes
	. $XBPS_SHUTILSDIR/pkgtarget_funcs.sh
	install_pkg $2
	;;
list|listfiles)
	if [ "$target" = "list" ]; then
		$XBPS_BIN_CMD list
		exit $?
	fi
	. $XBPS_SHUTILSDIR/pkgtarget_funcs.sh
	list_pkg_files $2
	;;
remove)
	[ -z "$2" ] && msg_error "missing package name after target."
	. $XBPS_SHUTILSDIR/pkgtarget_funcs.sh
	remove_pkg $2
	;;
stow)
	stow_flag=yes
	. $XBPS_SHUTILSDIR/tmpl_funcs.sh
	setup_tmpl $2
	. $XBPS_SHUTILSDIR/stow_funcs.sh
	stow_pkg $2
	;;
unstow)
	. $XBPS_SHUTILSDIR/tmpl_funcs.sh
	setup_tmpl $2
	. $XBPS_SHUTILSDIR/stow_funcs.sh
	unstow_pkg $2
	;;
*)
	echo "=> ERROR: invalid target: $target."
	usage
esac

# Agur
exit $?
