#!/bin/sh
#
# pkgfs - Builds source distribution files and stows/unstows them into
#	  a master directory, thanks to Xstow.
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
# 	- Multiple distfiles in a package.
#	- Multiple URLs to download source distribution files.
#	- Support GNU/BSD-makefile style source distribution files.
#	- Fix PKGFS_{C,CXX}FLAGS, aren't passed to the environment yet.
#	- Support adding filters to templates to avoid creating useless links.
#	- Save somewhere which package was stowned and use it to process deps.
#
# Default path to configuration file, can be overriden
# via the environment or command line.
#
: ${PKGFS_CONFIG_FILE:=/usr/local/etc/pkgfs.conf}

: ${progname:=$(basename $0)}
: ${topdir:=$(/bin/pwd -P 2>/dev/null)}
: ${fetch_cmd:=/usr/bin/ftp -a}
: ${cksum_cmd:=/usr/bin/cksum -a rmd160}
: ${awk_cmd:=/usr/bin/awk}
: ${mkdir_cmd:=/bin/mkdir -p}
: ${tar_cmd:=/usr/bin/tar}
: ${unzip_cmd:=/usr/pkg/bin/unzip}
: ${rm_cmd:=/bin/rm}
: ${mv_cmd:=/bin/mv}
: ${cp_cmd:=/bin/cp}
: ${sed_cmd=/usr/bin/sed}
: ${grep_cmd=/usr/bin/grep}
: ${gunzip_cmd:=/usr/bin/gunzip}
: ${bunzip2_cmd:=/usr/bin/bunzip2}
: ${patch_cmd:=/usr/bin/patch}
: ${find_cmd:=/usr/bin/find}
: ${file_cmd:=/usr/bin/file}
: ${ln_cmd:=/bin/ln}
: ${chmod_cmd:=/bin/chmod}

: ${xstow_version:=xstow-0.6.1-unstable}
: ${xstow_args:=-ap}

usage()
{
	cat << _EOF
$progname: [-bCef] [-c <config_file>] <target> <tmpl>

Targets
	info	Show information about <tmpl>.
	install	Build and install package from <tmpl>.
	remove	Remove package completely (unstow and remove from destdir)
	stow	Create symlinks from <tmpl> in master directory.
	unstow	Remove symlinks from <tmpl> in master directory.

Options
	-b	Only build the source distribution file(s).
	-C	Do not remove build directory after successful build.
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

run_file()
{
	local file="$1"

	check_path "$file"
	. $path_fixed

}

info_tmpl()
{
	local tmplfile="$1"
	if [ -z "$tmplfile" -o ! -f "$tmplfile" ]; then
		echo -n "*** ERROR: invalid template file '$tmplfile',"
		echo ", aborting ***"
		exit 1
	fi

	run_file ${tmplfile}

	echo " pkgfs template definitions:"
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

apply_tmpl_patches()
{
	if [ -z "$PKGFS_TEMPLATESDIR" ]; then
		echo -n "*** WARNING: PKGFS_TEMPLATESDIR is not set, "
		echo "won't apply patches ***"
		return 1
	fi

	#
	# If package needs some patches applied before building,
	# apply them now.
	#
	if [ -n "$patch_files" ]; then
		for i in ${patch_files}; do
			patch="$PKGFS_TEMPLATESDIR/$i"
			if [ ! -f "$patch" ]; then
				echo "*** WARNING: unexistent patch '$i' ***"
				continue
			fi

			# Try to guess if its a compressed patch.
			if $(echo $patch|$grep_cmd -q .gz); then
				$gunzip_cmd $patch
				patch=${patch%%.gz}
			elif $(echo $patch|$grep_cmd -q .bz2); then
				$bunzip2_cmd $patch
				patch=${patch%%.bz2}
			elif $(echo $patch|$grep_cmd -q .diff); then
				# nada
			else
				echo "*** WARNING: unknown patch type '$i' ***"
				continue
			fi

			cd $pkg_builddir && $patch_cmd < $patch 2>/dev/null
			if [ "$?" -eq 0 ]; then
				echo ">> Patch applied: \`$i'."
			else
				echo -n "*** ERROR: couldn't apply patch '$i'"
				echo ", aborting ***"
				exit 1
			fi
		done
	fi
}

check_build_vars()
{
	run_file ${PKGFS_CONFIG_FILE}
	PKGFS_CONFIG_FILE=$path_fixed

	if [ ! -f "$PKGFS_CONFIG_FILE" ]; then
		echo -n "*** ERROR: cannot find configuration file: "
		echo	"'$PKGFS_CONFIG_FILE' ***"
		exit 1
	fi

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

reset_tmpl_vars()
{
	local TMPL_VARS="pkgname extract_sufx distfiles url configure_args \
			make_build_args make_install_args build_style	\
			short_desc maintainer long_desc checksum wrksrc	\
			patch_files configure_env"

	for i in ${TMPL_VARS}; do
		unset $i
	done
}

check_tmpl_vars()
{
	local pkg="$1"
	local dfile=""

	[ -z "$pkg" ] && return 1

	if [ -n "$build_xstow" ]; then
		#
		# Looks like xstow is not available and we have to install it.
		#
		reset_tmpl_vars
		pkg="$PKGFS_TEMPLATESDIR/$xstow_version.tmpl"
		run_file ${pkg}
	fi

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

	if [ -z "$distfiles" ]; then
		dfile="$pkgname$extract_sufx"
	elif [ -n "${distfiles}" ]; then
		dfile="$distfiles$extract_sufx"
	else
		echo "*** ERROR unsupported fetch state ***"
		exit 1
	fi

	dfile="$PKGFS_SRC_DISTDIR/$dfile"

	case "$extract_sufx" in
	.tar.bz2|.tar.gz|.tgz|.tbz)
		extract_cmd="$tar_cmd xfz $dfile -C $PKGFS_BUILDDIR"
		;;
	.tar)
		extract_cmd="$tar_cmd xf $dfile -C $PKGFS_BUILDDIR"
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
	local file="$1"

	[ -z "$file" ] && return 1

	if [ -z "${distfiles}" ]; then
		dfile="$pkgname$extract_sufx"
	elif [ -n "${distfiles}" ]; then
		dfile="$distfiles$extract_sufx"
	else
		dfile="$file$extract_sufx"
	fi

	origsum="$checksum"
	dfile="$PKGFS_SRC_DISTDIR/$dfile"
	filesum="$($cksum_cmd $dfile | $awk_cmd '{print $4}')"
	if [ "$origsum" != "$filesum" ]; then
		echo "*** WARNING: checksum doesn't match (rmd160) ***"
		return 1
	fi
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

		echo ">>> Fetching \'$file2' source tarball"

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
	echo ">>> Extracting \`$pkgname' into $PKGFS_BUILDDIR."

	$extract_cmd
	if [ "$?" -ne 0 ]; then
		echo -n "*** ERROR: there was an error extracting the "
		echo "distfile, aborting *** "
		exit 1
	fi

	[ -n "$only_extract" ] && exit 0
}

fixup_tmpl_libtool()
{
	local lt_file="$pkg_builddir/libtool"

	#
	# If package has a libtool file replace it with ours, so that
	# we use the master directory while relinking, all will be fine
	# once the package is stowned.
	#
	if [ -f "$lt_file" -a -f "$PKGFS_MASTERDIR/bin/libtool" ]; then
		$rm_cmd -f $pkg_builddir/libtool
		$rm_cmd -f $pkg_builddir/ltmain.sh
		$ln_cmd -s $PKGFS_MASTERDIR/bin/libtool $lt_file
		$ln_cmd -s $PKGFS_MASTERDIR/share/libtool/config/ltmain.sh \
			 $pkg_builddir/ltmain.sh
	fi
}

build_tmpl_sources()
{
	local pkg_builddir=""

	export PATH="/bin:/sbin:/usr/bin:/usr/sbin:$PKGFS_MASTERDIR/bin:$PKGFS_MASTERDIR/sbin"

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
		echo "*** ERROR: unexistent build directory, aborting ***"
		exit 1
	fi

	# Apply patches if requested by template file
	apply_tmpl_patches

	echo ">>> Building \`$pkgname' (be patient, may take a while)"

	#
	# For now, just set LDFLAGS.
	#
	export LDFLAGS="-L$PKGFS_MASTERDIR/lib -Wl,-R$PKGFS_MASTERDIR/lib"
	#
	# Packages using GNU autoconf
	#
	if [ "$build_style" = "gnu_configure" ]; then
		for i in ${configure_env}; do
			[ -n "$i" ] && export $i
		done

		cd $pkg_builddir
		./configure	--prefix="$PKGFS_MASTERDIR" ${configure_args} \
				--mandir="$PKGFS_DESTDIR/$pkgname/man"

	#
	# Packages using propietary configure scripts.
	#
	elif [ "$build_style" = "configure" ]; then

		cd $pkg_builddir

		if [ -n "$configure_script" ]; then
			./$configure_script ${configure_args}
		else
			./configure ${configure_args}
		fi
	fi

	if [ "$?" -ne 0 ]; then
		echo "*** ERROR building (configure state) $pkgname ***"
		exit 1
	fi

	if [ -z "$make_cmd" ]; then
		MAKE_CMD="/usr/bin/make"
	else
		MAKE_CMD="$make_cmd"
	fi

	# Fixup libtool script if necessary
	fixup_tmpl_libtool

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

	unset LDFLAGS

	echo ">>> Installed \`$pkgname' into the master directory."

	if [ -d "$pkg_builddir" -a -z "$dontrm_builddir" ]; then
		$rm_cmd -rf $pkg_builddir
		[ "$?" -eq 0 ] && \
			echo ">> Removed \`$pkgname' build directory."
	fi

	cd $PKGFS_BUILDDIR
}

check_stow_cmd()
{
	local pkg="$1"

	[ -z "$pkg" ] && return 1

	# If we have the xstow binary it's done
	if [ -x "$PKGFS_XSTOW_CMD" ]; then
		unset build_xstow
		return 0
	fi

	#
	# Looks like we don't, build our own and re-adjust config file.
	# For now we use the latest available, because 0.5.1 doesn't
	# build with gcc4.
	#
	build_xstow=yes

	#
	# That's enough, build/install xstow and stow it!
	#
	install_tmpl "$pkg"
}

stow_tmpl()
{
	local pkg="$1"

	[ -z "$pkg" ] && return 2

	$PKGFS_XSTOW_CMD -dir $PKGFS_DESTDIR -target $PKGFS_MASTERDIR \
		${xstow_args} $PKGFS_DESTDIR/$pkg
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR: couldn't create symlinks for \`$pkg' ***"
		exit 1
	else
		echo ">>> Created \`$pkg' symlinks into master directory."
	fi

	if [ -n "$build_xstow" ]; then
		check_path "$PKGFS_CONFIG_FILE"
		$sed_cmd -e "s|PKGFS_XSTOW_.*|PKGFS_XSTOW_CMD=$PKGFS_MASTERDIR/bin/xstow|" \
			$path_fixed > $path_fixed.in && \
			$mv_cmd $path_fixed.in $path_fixed
	fi

}

unstow_tmpl()
{
	local pkg="$1"

	if [ -z "$pkg" ]; then
		echo "*** ERROR: template wasn't specified? ***"
		exit 1
	fi

	local tmppkg="${pkg%-[0-9]*}"
	if [ "$tmppkg" = "xstow" ]; then
		echo "*** INFO: You aren't allowed to unstow \`$xstow_version'."
		exit 1
	fi

	$PKGFS_XSTOW_CMD -dir $PKGFS_DESTDIR -target $PKGFS_MASTERDIR \
		-D $PKGFS_DESTDIR/$pkg
	if [ "$?" -ne 0 ]; then
		exit 1
	else
		echo ">>> Removed \`$pkg' symlinks from master directory."
	fi
}

install_tmpl()
{
	tmplfile="$1"
	if [ -z "$build_xstow" ]; then
		if [ -z "$tmplfile" -o ! -f "$tmplfile" ]; then
			echo -n "*** ERROR: invalid template file '$tmplfile',"
			echo " aborting ***"
			exit 1
		fi
		check_build_vars
	fi

	run_file ${tmplfile}
	tmplfile=$path_fixed
	prev_tmpl=$path_fixed

	check_tmpl_vars ${pkgname}

	if [ -n "$only_build" ]; then
		build_tmpl_sources
		exit 0
	fi

	fetch_tmpl_sources
	extract_tmpl_sources
	build_tmpl_sources

	if [ -n "$build_xstow" ]; then
		#
		# We must use the temporary path until xstow is stowned.
		#
		PKGFS_XSTOW_CMD="$PKGFS_DESTDIR/$xstow_version/bin/xstow"
		stow_tmpl $xstow_version
		#
		# xstow has been stowned, now stown the origin package.
		#
		run_file ${prev_tmpl}
		tmplfile=${prev_tmpl}
	fi

	check_stow_cmd ${tmplfile}
	[ "$?" -eq 1 ] && return 0

	stow_tmpl $pkgname
	reset_tmpl_vars
}

remove_tmpl()
{
	local pkg="$1"

	if [ -z "$pkg" ]; then
		echo "*** ERROR: unexistent package, aborting ***"
		exit 1
	fi

	run_file ${PKGFS_CONFIG_FILE}

	if [ ! -d "$PKGFS_DESTDIR/$pkg" ]; then
		echo "*** ERROR: cannot find package on $PKGFS_DESTDIR ***"
		exit 1
	fi

	unstow_tmpl ${pkg}
	$rm_cmd -rf $PKGFS_DESTDIR/$pkg
	return $?
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
		dontrm_builddir=yes
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

# Main switch
case "$target" in
info)
	info_tmpl "$2"
	;;
install)
	install_tmpl "$2"
	;;
remove)
	remove_tmpl "$2"
	;;
stow)
	run_file ${PKGFS_CONFIG_FILE}
	stow_tmpl "$2"
	;;
unstow)
	run_file ${PKGFS_CONFIG_FILE}
	unstow_tmpl "$2"
	;;
*)
	echo "*** ERROR invalid target '$target' ***"
	usage
esac

# Agur
exit 0
