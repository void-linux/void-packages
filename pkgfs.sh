#!/bin/sh
#
# pkgfs - Builds source distribution files.
#
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
#
# TODO
# 	Multiple distfiles in a package.
#	Multiple URLs to download source distribution files.
#	Support GNU/BSD-makefile style source distribution files.
# 	Actually do the symlink dance (stow/unstow).
#	Fix PKGFS_{C,CXX}FLAGS, aren't passed to the environment yet.
#
#
# Default path to configuration file, can be overriden
# via the environment or command line.
#
: ${PKGFS_CONFIG_FILE:=/usr/local/etc/pkgfs.conf}

# Global private stuff
: ${progname:=$(basename $0)}
: ${topdir:=$(/bin/pwd -P 2>/dev/null)}
: ${fetch_cmd:=/usr/bin/ftp -a}
: ${cksum_cmd:=/usr/bin/cksum -a rmd160}
: ${awk_cmd:=/usr/bin/awk}
: ${mkdir_cmd:=/bin/mkdir -p}
: ${tar_cmd:=/usr/bin/tar}
: ${unzip_cmd:=/usr/pkg/bin/unzip}
: ${rm_cmd:=/bin/rm}

usage()
{
	cat << _EOF
$progname: [-bCef] [-c <config_file>] <target> <tmpl>

Targets
	build	Build source distribution from <tmpl>.
	info	Show information about <tmpl>.
	stow	Create symlinks from <tmpl> in master directory.
	unstow	Remove symlinks from <tmpl> in master directory.

Options
	-b	Only build the source distribution file(s).
	-C	Clean build directory after successful build.
	-c	Path to global configuration file.
		If not specified /usr/local/etc/pkgfs.conf is used.
	-e	Only extract the source distribution file(s).
	-f	Only fetch the source distribution file(s).

_EOF
	exit 1
}

check_path()
{
	eval local orig="$1"

	case "$orig" in
	/)
		;;
	/*)
		orig="${orig%/}"
		;;
	*)
		orig="$topdir/${orig%/}"
		;;
	esac

	path_fixed="$orig"
}

info_tmpl()
{
	echo "pkgfs template source distribution:"
	echo
	echo "	pkgname:	$pkgname"
	for i in "${distfiles}"; do
		[ -n "$i" ] && echo "	distfile:	$i"
	done
	echo "	URL:		$url"
	echo "	maintainer:	$maintainer"
	[ -n $checksum ] && echo "	checksum:	$checksum"
	echo "	build_style:	$build_style"
	echo "	short_desc:	$short_desc"
	echo "$long_desc"
}

check_build_vars()
{
	if [ ! -f "$PKGFS_CONFIG_FILE" ]; then
		echo -n "*** ERROR: cannot find configuration file: "
		echo	"'$PKGFS_CONFIG_FILE' ***"
		exit 1
	fi

	check_path "$PKGFS_CONFIG_FILE"
	. $path_fixed

	local PKGFS_VARS="PKGFS_MASTERDIR PKGFS_DESTDIR PKGFS_BUILDDIR \
			  PKGFS_SRC_DISTDIR"

	for f in ${PKGFS_VARS}; do
		eval val="\$$f"
		if [ -z "$val" ]; then
			echo "**** ERROR: '$f' not set in configuration "
			echo "file, aborting ***"
			exit 1
		fi
		if [ ! -d "$f" ]; then
			$mkdir_cmd "$val"
			if [ "$?" -ne 0 ]; then
				echo -n "*** ERROR: couldn't create '$f'"
				echo "directory, aborting ***"
				exit 1
			fi
		fi
	done
}

check_tmpl_vars()
{
	local dfile=""

	if [ -z "$distfiles" ]; then
		dfile="$pkgname$extract_sufx"
	elif [ -n "${distfiles}" ]; then
		dfile="$distfiles$extract_sufx"
	else
		echo "*** ERROR unsupported fetch state ***"
		exit 1
	fi

	dfile="$PKGFS_SRC_DISTDIR/$dfile"

	REQ_VARS="pkgname extract_sufx url build_style"

	# Check if required vars weren't set.
	for i in ${REQ_VARS}; do
		eval val="\$$i"
		if [ -z "$val" -o -z "$i" ]; then
			echo -n "*** ERROR: $i not set (incomplete template"
			echo	" build file), aborting ***"
			exit 1
		fi
	done

	case "$extract_sufx" in
	.tar.bz2|.tar.gz|.tgz|.tbz)
		extract_cmd="$tar_cmd xvfz $dfile -C $PKGFS_BUILDDIR"
		;;
	.tar)
		extract_cmd="$tar_cmd xvf $dfile -C $PKGFS_BUILDDIR"
		;;
	.zip)
		extract_cmd="$unzip_cmd -x $dfile -C $PKGFS_BUILDDIR"
		;;
	*)
		echo -n "*** ERROR: unknown 'extract_sufx' argument in build "
		echo	"file ***"
		exit 1
		;;
	esac
}

check_rmd160_cksum()
{
	local passed_var="$1"

	if [ -z "${distfiles}" ]; then
		dfile="$pkgname$extract_sufx"
	elif [ -n "${distfiles}" ]; then
		dfile="$distfiles$extract_sufx"
	else
		dfile="$passed_var$extract_sufx"
	fi

	origsum="$checksum"
	dfile="$PKGFS_SRC_DISTDIR/$dfile"
	filesum="$($cksum_cmd $dfile | $awk_cmd '{print $4}')"
	if [ "$origsum" != "$filesum" ]; then
		echo "*** WARNING: checksum doesn't match (rmd160) ***"
		return 1
	fi

	return 0
}

fetch_tmpl_sources()
{
	local file=""
	local file2=""

	if [ -z "$distfiles" ]; then
		file="$pkgname"
	else
		file="$distfiles"
	fi

	for f in "$file"; do
		file2="$f$extract_sufx"
		if [ -f "$PKGFS_SRC_DISTDIR/$file2" ]; then
			check_rmd160_cksum $f
			if [ "$?" -eq 0 ]; then
				if [ -n "$only_fetch" ]; then
					echo "=> checksum ok"
					exit 0
				fi
				return 0
			fi
		fi

		echo "*** Fetching source distribution file '$file2' ***"

		cd $PKGFS_SRC_DISTDIR && $fetch_cmd $url/$file2
		if [ "$?" -ne 0 ]; then
			if [ ! -f $PKGFS_SRC_DISTDIR/$file2 ]; then
				echo -n "*** ERROR: couldn't fetch '$file2', "
				echo	"aborting ***"
			else
				echo -n "*** ERROR: there was an error "
				echo	"fetching '$file2', aborting ***"
			fi
			exit 1
		else
			if [ -n "$only_fetch" ]; then
				echo "=> checksum ok"
				exit 0
			fi
		fi
	done
}

extract_tmpl_sources()
{
	echo "***"
	echo "*** Extracting source distribution from $pkgname ***"
	echo "***"

	$extract_cmd
	if [ "$?" -ne 0 ]; then
		echo -n "*** ERROR: there was an error extracting the "
		echo "distfile, aborting *** "
		exit 1
	fi

	[ -n "$only_extract" ] && exit 0
}

build_tmpl_sources()
{
	local pkg_builddir=""

	if [ -z "$wrksrc" ]; then
		if [ -z "$distfiles" ]; then
			pkg_builddir=$PKGFS_BUILDDIR/$pkgname
		else
			pkg_builddir=$PKGFS_BUILDDIR/$distfiles
		fi
	else
		pkg_builddir=$PKGFS_BUILDDIR/$wrksrc
	fi

	if [ ! -d "$pkg_builddir" ]; then
		echo "*** ERROR: build directory does not exist, aborting ***"
		exit 1
	fi

	echo "***"
	echo "*** Building binary distribution from $pkgname ***"
	echo "***"

	cd $pkg_builddir
	#
	# Packages using GNU autoconf
	#
	if [ "$build_style" = "gnu_configure" ]; then
		for i in "${configure_env}"; do
			[ -n "$i" ] && export "$i"
		done

		./configure --prefix="$PKGFS_DESTDIR" "$configure_args"
		if [ "$?" -ne 0 ]; then
			echo -n "*** ERROR building (configure state)"
			echo " $pkgname ***"
			exit 1
		fi
		if [ -z "$make_cmd" ]; then
			MAKE_CMD="/usr/bin/make"
		else
			MAKE_CMD="$make_cmd"
		fi

		${MAKE_CMD} ${make_build_args}
		if [ "$?" -ne 0 ]; then
			echo "*** ERROR building (make stage) $pkgname ***"
			exit 1
		fi

		${MAKE_CMD} ${make_install_args} \
			install prefix="$PKGFS_DESTDIR/$pkgname"
		if [ "$?" -ne 0 ]; then
			echo "*** ERROR instaling $pkgname ***"
			exit 1
		fi

		echo "***"
		echo "*** binary distribution built for $pkgname ***"

		if [ -d "$pkg_builddir" -a -n "$clean_builddir" ]; then
			$rm_cmd -rf $pkg_builddir
			[ "$?" -eq 0 ] && echo "***  removed build directory"
		fi

		echo "***"
	fi
}

build_tmpl()
{
	local save_path="$PATH"

	export PATH="/bin:/sbin:/usr/bin:/usr/sbin:$PKGFS_DESTDIR/bin:$PKGFS_DESTDIR/sbin"

	check_build_vars
	check_tmpl_vars

	if [ "$only_build" ]; then
		build_tmpl_sources
		exit 0
	fi

	fetch_tmpl_sources
	extract_tmpl_sources
	build_tmpl_sources
	build_tmp_symlinks

	export PATH="$save_path"
}

#
# main()
#
args=$(getopt bCc:ef $*)
[ "$?" -ne 0 ] && usage

set -- $args
while [ "$#" -gt 0 ]; do
	case "$1" in
	-b)
		only_build=yes
		;;
	-C)
		clean_builddir=yes
		;;
	-c)
		PKGFS_CONFIG_FILE="$2"
		shift
		;;
	-e)
		only_extract=yes
		;;
	-f)
		only_fetch=yes
		;;
	--)
		shift
		break
		;;
	esac
	shift
done

[ "$#" -gt 2 ] && usage

target="$1"
if [ -z "$target" ]; then
	echo "*** ERROR missing target ***"
	usage
fi

tmplfile="$2"
if [ -z "$tmplfile" -o ! -f "$tmplfile" ]; then
	echo "*** ERROR: invalid template file '$tmplfile', aborting ***"
	exit 1
fi

check_path "$tmplfile"
. $path_fixed


# Main switch
case "$target" in
build)
	build_tmpl
	;;
info)
	info_tmpl
	;;
*)
	echo "*** ERROR invalid target '$target' ***"
	usage
esac

# Agur
exit 0
