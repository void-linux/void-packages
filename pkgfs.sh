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
#	- Implement a routine that checks if installed version is sufficient
#	  to satisfy the required dependency... right now it's very prone
#	  to errors and slow.
# 	- Multiple distfiles in a package.
#	- Multiple URLs to download source distribution files.
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
: ${db_cmd:=/usr/bin/db -q}
: ${chmod_cmd:=/bin/chmod}

: ${xstow_args:=-ap}
: ${xstow_ignore_files:=perllocal.pod}	# XXX For now ignore them.

set_defvars()
{
	# Directories
	: ${PKGFS_TEMPLATESDIR:=$PKGFS_DISTRIBUTIONDIR/templates}
	: ${PKGFS_DEPSDIR:=$PKGFS_DISTRIBUTIONDIR/dependencies}
	: ${PKGFS_BUILD_DEPS_DB:=$PKGFS_DEPSDIR/build-depends.db}
	: ${PKGFS_TMPLHELPDIR:=$PKGFS_DISTRIBUTIONDIR/helper-templates}
	: ${PKGFS_REGPKG_DB:=$PKGFS_DESTDIR/.pkgfs-registered-pkgs.db}

	local DDIRS="PKGFS_DEPSDIR PKGFS_TEMPLATESDIR PKGFS_TMPLHELPDIR"
	for i in ${DDIRS}; do
		eval val="\$$i"
		if [ ! -d "$val" ]; then
			echo "**** ERROR: cannot find $i, aborting ***"
			exit 1
		fi
	done
}

usage()
{
	cat << _EOF
$progname: [-bCefi] [-c <config_file>] <target> <tmplname>

Targets
	info	Show information about <tmplname>.
	install	Build and install package from <tmplname>.
	list	Lists and prints short description about installed packages.
	remove	Remove package completely (unstow and remove from destdir)
	stow	Create symlinks from <tmplname> in master directory.
	unstow	Remove symlinks from <tmplname> in master directory.

Options
	-b	Only build the source distribution file(s), without
		extracting or fetching before.
	-C	Do not remove build directory after successful build.
	-c	Path to global configuration file.
		If not specified /usr/local/etc/pkgfs.conf is used.
	-e	Only extract the source distribution file(s).
	-f	Only fetch the source distribution file(s).
	-i	Only build and install the binary distribution file(s)
		into the destdir directory, without stowning.
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

#
# This function merges two GNU info dirs into one and puts the result
# into PKGFS_MASTERDIR/share/info/dir.
#
merge_infodir_tmpl()
{
	local pkgname="$1"
	local merge_info_cmd="$PKGFS_MASTERDIR/bin/merge-info"

	[ -z "$pkgname" ] && return 1
	[ ! -r "$PKGFS_MASTERDIR/share/info/dir" ] && return 1
	[ ! -r "$PKGFS_DESTDIR/$pkgname/share/info/dir" ] && return 1

	$merge_info_cmd -d $PKGFS_MASTERDIR/share/info/dir 	\
		$PKGFS_DESTDIR/$pkgname/share/info/dir -o 	\
		$PKGFS_MASTERDIR/share/info/dir.new
	if [ "$?" -ne 0 ]; then
		echo -n "*** WARNING: there was an error merging info dir from"
		echo " $pkgname, aborting ***"
		return 1
	fi

	$mv_cmd -f $PKGFS_MASTERDIR/share/info/dir.new \
		$PKGFS_MASTERDIR/share/info/dir
}

#
# Shows info about a template.
#
info_tmpl()
{
	local tmpl="$1"
	if [ -z "$tmpl" -o ! -f "$PKGFS_TEMPLATESDIR/$tmpl.tmpl" ]; then
		echo -n "*** ERROR: invalid template file \`$tmpl' ***"
		echo ", aborting ***"
		exit 1
	fi

	run_file $PKGFS_TEMPLATESDIR/$tmpl.tmpl

	echo "pkgname:	$pkgname"
	echo "version:	$version"
	for i in "${distfiles}"; do
		[ -n "$i" ] && echo "distfile:	$i"
	done
	echo "URL:		$url"
	echo "maintainer:	$maintainer"
	[ -n $checksum ] && echo "checksum:	$checksum"
	echo "build_style:	$build_style"
	echo "short_desc:	$short_desc"
	echo "$long_desc"
	echo
	check_build_depends_tmpl $pkgname-$version
	if [ "$?" -eq 0 ]; then
		local list="$($db_cmd -V btree $PKGFS_BUILD_DEPS_DB $pkgname)"
		echo "This package requires the following dependencies to be built:"
		for i in ${list}; do
			echo " $i"
		done
	fi
}

#
# Applies to the build directory the patches specified by a template.
#
apply_tmpl_patches()
{
	local patch=

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

			$cp_cmd -f $patch $wrksrc

			# Try to guess if its a compressed patch.
			if $(echo $patch|$grep_cmd -q .gz); then
				$gunzip_cmd $wrksrc/$i
				patch=${i%%.gz}
			elif $(echo $patch|$grep_cmd -q .bz2); then
				$bunzip2_cmd $wrksrc/$i
				patch=${i%%.bz2}
			elif $(echo $patch|$grep_cmd -q .diff); then
				patch=$i
			else
				echo "*** WARNING: unknown patch type '$i' ***"
				continue
			fi

			cd $wrksrc && $patch_cmd < $patch 2>/dev/null
			if [ "$?" -eq 0 ]; then
				echo "=> Patch applied: \`$i'."
			else
				echo -n "*** ERROR: couldn't apply patch '$i'"
				echo ", aborting ***"
				exit 1
			fi
		done
	fi
}

#
# Checks that all required variables specified in the configuration
# file are properly working.
#
check_config_vars()
{
	local cffound=

	if [ -z "$config_file_specified" ]; then
		config_file_paths="$PKGFS_CONFIG_FILE ./pkgfs.conf"
		for f in $config_file_paths; do
			[ -f $f ] && PKGFS_CONFIG_FILE=$f && \
				cffound=yes && break
		done
		if [ -z "$cffound" ]; then
			echo -n "*** ERROR: config file not specified "
			echo "and not in default location or current dir ***"
			exit 1
		fi
	fi

	run_file ${PKGFS_CONFIG_FILE}
	PKGFS_CONFIG_FILE=$path_fixed

	if [ ! -f "$PKGFS_CONFIG_FILE" ]; then
		echo -n "*** ERROR: cannot find configuration file: "
		echo	"'$PKGFS_CONFIG_FILE' ***"
		exit 1
	fi

	local PKGFS_VARS="PKGFS_MASTERDIR PKGFS_DESTDIR PKGFS_BUILDDIR \
			  PKGFS_SRCDISTDIR PKGFS_SYSCONFDIR"

	for f in ${PKGFS_VARS}; do
		eval val="\$$f"
		if [ -z "$val" ]; then
			echo -n "**** ERROR: '$f' not set in configuration "
			echo "file, aborting ***"
			exit 1
		fi

		if [ ! -d "$val" ]; then
			$mkdir_cmd "$val"
			if [ "$?" -ne 0 ]; then
				echo -n "*** ERROR: couldn't create '$f'"
				echo "directory, aborting ***"
				exit 1
			fi
		fi
	done
}

#
# Resets all vars used by a template.
#
reset_tmpl_vars()
{
	local TMPL_VARS="pkgname extract_sufx distfiles url configure_args \
			make_build_args make_install_args build_style	\
			short_desc maintainer long_desc checksum wrksrc	\
			patch_files configure_env make_cmd pkgconfig_override \
			configure_env make_env run_stuff_before run_stuff_after \
			run_stuff_before_configure_file run_stuff_before_build_file \
			run_stuff_before_install_file run_stuff_after_install \
			run_stuff_after_install_file make_build_target \
			run_stuff_before_configure_cmd run_stuff_before_build_cmd \
			run_stuff_before_install_cmd run_stuff_after_install_cmd \
			make_install_target postinstall_helpers version \
			ignore_files"

	for i in ${TMPL_VARS}; do
		eval unset "$i"
	done
}

#
# Checks some vars used in templates and sets $extract_cmd.
#
check_tmpl_vars()
{
	local pkg="$1"
	local dfile=""

	[ -z "$pkg" ] && return 1
	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	REQ_VARS="pkgname version extract_sufx url build_style"

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
		dfile="$pkgname-$version$extract_sufx"
	elif [ -n "${distfiles}" ]; then
		dfile="$distfiles$extract_sufx"
	else
		echo "*** ERROR unsupported fetch state ***"
		exit 1
	fi

	dfile="$PKGFS_SRCDISTDIR/$dfile"

	case "$extract_sufx" in
	.tar.bz2|.tar.gz|.tgz|.tbz)
		extract_cmd="$tar_cmd xfz $dfile -C $PKGFS_BUILDDIR"
		;;
	.tar)
		extract_cmd="$tar_cmd xf $dfile -C $PKGFS_BUILDDIR"
		;;
	.zip)
		if [ -f "$PKGFS_TMPLHELPDIR/unzip-extraction.sh" ]; then
			. $PKGFS_TMPLHELPDIR/unzip-extraction.sh
		fi
		# $extract_cmd set by the helper
		;;
	*)
		echo -n "*** ERROR: unknown 'extract_sufx' argument in build "
		echo	"file ***"
		exit 1
		;;
	esac
}

#
# Verifies that a checksum of a distfile is correct.
#
check_rmd160_cksum()
{
	local file="$1"
	local dfile=

	[ -z "$file" ] && return 1

	if [ -z "${distfiles}" ]; then
		dfile="$pkgname-$version$extract_sufx"
	elif [ -n "${distfiles}" ]; then
		dfile="$distfiles$extract_sufx"
	else
		dfile="$file$extract_sufx"
	fi

	if [ -z "$checksum" ]; then
		echo "*** ERROR: checksum unset in template file for \`$pkgname' ***"
		exit 1
	fi

	origsum="$checksum"
	dfile="$PKGFS_SRCDISTDIR/$dfile"
	filesum="$($cksum_cmd $dfile | $awk_cmd '{print $4}')"
	if [ "$origsum" != "$filesum" ]; then
		echo "*** WARNING: checksum doesn't match (rmd160) ***"
		return 1
	fi

	echo "==> RMD160 checksum ok for \`$pkgname-$version'."
}

#
# Downloads the distfiles for a template from $url.
#
fetch_tmpl_sources()
{
	local file=""
	local file2=""

	[ -z "$pkgname" ] && return 1
	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ -z "$distfiles" ]; then
		file="$pkgname-$version"
	else
		file="$distfiles"
	fi

	for f in "$file"; do
		file2="$f$extract_sufx"
		if [ -f "$PKGFS_SRCDISTDIR/$file2" ]; then
			check_rmd160_cksum $f
			if [ "$?" -eq 0 ]; then
				if [ -n "$only_fetch" ]; then
					echo "=> checksum ok"
					exit 0
				fi
				return 0
			fi
		fi

		echo "==> Fetching \`$file2' source tarball."

		cd $PKGFS_SRCDISTDIR && $fetch_cmd $url/$file2
		if [ "$?" -ne 0 ]; then
			if [ ! -f $PKGFS_SRCDISTDIR/$file2 ]; then
				echo -n "*** ERROR: couldn't fetch '$file2', "
				echo	"aborting ***"
			else
				echo -n "*** ERROR: there was an error "
				echo	"fetching '$file2', aborting ***"
			fi
			exit 1
		else
			if [ -n "$only_fetch" ]; then
				exit 0
			fi
		fi
	done
}

#
# Extracts contents of a distfile specified in a template into
# the build directory.
#
extract_tmpl_sources()
{
	[ -z "$pkgname" ] && return 1

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	echo "==> Extracting \`$pkgname-$version' into $PKGFS_BUILDDIR."

	$extract_cmd
	if [ "$?" -ne 0 ]; then
		echo -n "*** ERROR: there was an error extracting the "
		echo "distfile, aborting *** "
		exit 1
	fi

	unset extract_cmd
	[ -n "$only_extract" ] && exit 0
}

fixup_tmpl_libtool()
{
	local lt_file="$wrksrc/libtool"

	#
	# If package has a libtool file replace it with ours, so that
	# we use the master directory while relinking, all will be fine
	# once the package is stowned.
	#
	if [ -f "$lt_file" -a -f "$PKGFS_MASTERDIR/bin/libtool" ]; then
		$rm_cmd -f $wrksrc/libtool
		$rm_cmd -f $wrksrc/ltmain.sh
		$ln_cmd -s $PKGFS_MASTERDIR/bin/libtool $lt_file
		$ln_cmd -s $PKGFS_MASTERDIR/share/libtool/config/ltmain.sh \
			 $wrksrc/ltmain.sh
	elif [ -f "$PKGFS_MASTERDIR/bin/libtool" ]; then
		$ln_cmd -s $PKGFS_MASTERDIR/bin/libtool $lt_file
	fi
}

set_build_vars()
{
	LDFLAGS="-L$PKGFS_MASTERDIR/lib -Wl,-R$PKGFS_MASTERDIR/lib $LDFLAGS"
	LDFLAGS="-L$PKGFS_DESTDIR/$pkg/lib $LDFLAGS"
	CFLAGS="$CFLAGS $PKGFS_CFLAGS"
	CXXFLAGS="$CXXFLAGS $PKGFS_CXXFLAGS"
	CPPFLAGS="-I$PKGFS_MASTERDIR/include $CPPFLAGS"
	PKG_CONFIG="$PKGFS_MASTERDIR/bin/pkg-config"

	export LDFLAGS="$LDFLAGS" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
	export CPPFLAGS="$CPPFLAGS" PKG_CONFIG="$PKG_CONFIG"
}

unset_build_vars()
{
	unset LDFLAGS CFLAGS CXXFLAGS CPPFLAGS PKG_CONFIG
}

#
# Configures, builds and installs a package into the destination
# directory.
#
build_tmpl_sources()
{
	local pkg="$pkgname-$version"

	[ -z "$pkgname" -o -z "$version" ] && return 1
        #
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ -n "$distfiles" -a -z "$wrksrc" ]; then
		wrksrc=$PKGFS_BUILDDIR/$distfiles
	elif [ -z "$wrksrc" ]; then
		wrksrc=$PKGFS_BUILDDIR/$pkg
	else
		wrksrc=$PKGFS_BUILDDIR/$wrksrc
	fi

	if [ ! -d "$wrksrc" ]; then
		echo "*** ERROR: unexistent build directory, aborting ***"
		exit 1
	fi

	export PATH="/bin:/sbin:/usr/bin:/usr/sbin:$PKGFS_MASTERDIR/bin:$PKGFS_MASTERDIR/sbin"

	# Apply patches if requested by template file
	apply_tmpl_patches

	echo "==> Building \`$pkg' (be patient, may take a while)"

	# Run stuff before configure.
	for i in "$run_stuff_before"; do
		if [ "$i" = "configure" ]; then
			[ -f $run_stuff_before_configure_file ] && \
				. $run_stuff_before_configure_file
			[ -n "$run_stuff_before_configure_cmd" ] && \
				${run_stuff_before_configure_cmd}
		fi
	done

	# Export configure_env vars.
	for f in ${configure_env}; do
		export "$f"
	done

	#
	# Packages using GNU autoconf
	#
	if [ "$build_style" = "gnu_configure" ]; then
		cd $wrksrc
		set_build_vars
		#
		# Pass consistent arguments to not have unexpected
		# surprises later.
		#
		./configure						\
			--prefix="$PKGFS_MASTERDIR"			\
			--mandir="$PKGFS_DESTDIR/$pkg/man"		\
			--infodir="$PKGFS_DESTDIR/$pkg/share/info"	\
			--sysconfdir="$PKGFS_SYSCONFDIR"		\
			${configure_args}

	#
	# Packages using propietary configure scripts.
	#
	elif [ "$build_style" = "configure" ]; then
		cd $wrksrc
		if [ -n "$configure_script" ]; then
			./$configure_script ${configure_args}
		else
			./configure ${configure_args}
		fi
	#
	# Packages that are perl modules and use Makefile.PL files.
	# They are all handled by the helper perl-module.sh.
	#
	elif [ "$build_style" = "perl_module" ]; then
		. $PKGFS_TMPLHELPDIR/perl-module.sh
		perl_module_build $pkgname

	#
	# Packages with BSD or GNU Makefiles are easy, just skip
	# the configure stage and proceed.
	#
	elif [ "$build_style" = "bsd_makefile" -o \
	       "$build_style" = "gnu_makefile" ]; then

	       cd $wrksrc
	#
	# Unknown build_style type won't work :-)
	#
	else
		echo "*** ERROR unknown build_style $build_style, aborting ***"
		exit 1
	fi

	if [ "$build_style" != "perl_module" -a "$?" -ne 0 ]; then
		echo "*** ERROR building (configure state) \`$pkg' ***"
		exit 1
	fi

	# unset configure_env vars.
	for f in ${configure_env}; do
		unset eval ${f%=*}
	done

	#
	# Assume BSD make if make_cmd not set in template.
	#
	if [ -z "$make_cmd" ]; then
		make_cmd="/usr/bin/make"
	fi

	# Fixup libtool script if necessary
	fixup_tmpl_libtool

	#
	# Run template stuff before building.
	#
	for i in ${run_stuff_before}; do
		if [ "$i" = "build" ]; then
			[ -f $run_stuff_before_build_file ] && \
				. $run_stuff_before_build_file
			[ -n "$run_stuff_before_build_cmd" ] && \
				${run_stuff_before_build_cmd}
		fi
	done

	[ -z "$make_build_target" ] && make_build_target=
	[ -n "$PKGFS_MAKEJOBS" ] && PKGFS_MAKEJOBS="-j$PKGFS_MAKEJOBS"

	# Export make_env vars.
	for f in ${make_env}; do
		export "$f"
	done

	#
	# Build package via make.
	#
	${make_cmd} ${PKGFS_MAKEJOBS} ${make_build_args} ${make_build_target}
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR building (make stage) \`$pkg' ***"
		exit 1
	fi

	#
	# Run template stuff before installing.
	#
	for i in ${run_stuff_before}; do
		if [ "$i" = "install" ]; then
			[ -f $run_stuff_before_install_file ] && \
				. $run_stuff_before_install_file
			[ -n "$run_stuff_before_install_cmd" ] && \
				${run_stuff_before_install_cmd}
		fi
	done

	[ -z "$make_install_target" ] && make_install_target=install

	#
	# Install package via make.
	#
	${make_cmd} ${make_install_args} ${make_install_target} \
		prefix="$PKGFS_DESTDIR/$pkg"
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR instaling \`$pkg' ***"
		exit 1
	fi

	# Unset make_env vars.
	for f in ${make_env}; do
		unset eval ${f%=*}
	done

	#
	# Run template stuff after installing.
	#
	for i in ${run_stuff_after}; do
		if [ "$i" = "install" ]; then
			[ -f $run_stuff_after_install_file ] && \
				. $run_stuff_after_install_file
			[ -n "$run_stuff_after_install_cmd" ] && \
				${run_stuff_after_install_cmd}
		fi
	done

	#
	# Transform pkg-config files if requested by template.
	#
	for i in ${pkgconfig_override}; do
		local tmpf="$PKGFS_DESTDIR/$pkg/lib/pkgconfig/$i"
		[ -f "$tmpf" ] && \
			[ -f $PKGFS_TMPLHELPDIR/pkg-config-transform.sh ] && \
			. $PKGFS_TMPLHELPDIR/pkg-config-transform.sh && \
			pkgconfig_transform_file $tmpf
	done

	# Unset build vars.
	unset_build_vars

	echo "==> Installed \`$pkg' into $PKGFS_DESTDIR/$pkg."

	#
	# Remove $wrksrc if -C not specified.
	#
	if [ -d "$wrksrc" -a -z "$dontrm_builddir" ]; then
		$rm_cmd -rf $wrksrc
		[ "$?" -eq 0 ] && \
			echo "=> Removed \`$pkg' build directory."
	fi

	cd $PKGFS_BUILDDIR
}

#
# Stows a currently installed package, i.e creates the links
# on the master directory.
#
stow_tmpl()
{
	local pkg="$1"
	local infodir_pkg="share/info/dir"
	local infodir_master="$PKGFS_MASTERDIR/share/info/dir"
	local real_xstowargs="$xstow_args"
	local real_xstow_ignore="$xstow_ignore_files"

	[ -z "$pkg" ] && return 2

	if [ -n "$stow_flag" ]; then
		pkg=$PKGFS_TEMPLATESDIR/$pkg.tmpl
		run_file $pkg
		pkg=$pkgname-$version
		#
		# You cannot stow a meta-template.
		#
		[ "$build_style" = "meta-template" ] && return 0
	fi

	if [ -r "$PKGFS_DESTDIR/$pkg/$infodir_pkg" ]; then
		merge_infodir_tmpl $pkg
	fi

	if [ -r "$PKGFS_DESTDIR/$pkg/$infodir_pkg" \
	     -a -r "$infodir_master" ]; then
		xstow_args="$xstow_args -i-file-in-dir $infodir_pkg"
	fi

	if [ -n "$ignore_files" ]; then
		xstow_ignore_files="$xstow_ignore_files $ignore_files"
	fi

	$PKGFS_XSTOW_CMD -ignore "${xstow_ignore_files}" ${xstow_args} \
		-pd-targets $PKGFS_MASTERDIR \
		-dir $PKGFS_DESTDIR -target $PKGFS_MASTERDIR \
		$PKGFS_DESTDIR/$pkg
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR: couldn't create symlinks for \`$pkg' ***"
		exit 1
	else
		echo "==> Created \`$pkg' symlinks into master directory."
	fi

	installed_tmpl_handler register $pkgname $version

	#
	# Run template postinstall helpers if requested.
	#
	if [ "$pkgname" != "${pkg%%-$version}" ]; then
		run_file $PKGFS_TEMPLATESDIR/${pkg%%-$version}.tmpl
	fi

	for i in ${postinstall_helpers}; do
		local pihf="$PKGFS_TMPLHELPDIR/$i"
		[ -f "$pihf" ] && . $pihf
	done

	xstow_ignore_files="$real_xstow_ignore"
	xstow_args="$real_xstowargs"
}

#
# Unstows a currently stowned package, i.e removes its links
# from the master directory.
#
unstow_tmpl()
{
	local pkg="$1"
	local real_xstow_ignore="$xstow_ignore_files"

	if [ -z "$pkg" ]; then
		echo "*** ERROR: template wasn't specified? ***"
		exit 1
	fi

	if [ "$pkg" = "xstow" ]; then
		echo "*** INFO: You aren't allowed to unstow \`$pkg'."
		exit 1
	fi

	run_file $PKGFS_TEMPLATESDIR/$pkg.tmpl

	#
	# You cannot unstow a meta-template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ -n "$ignore_files" ]; then
		xstow_ignore_files="$xstow_ignore_files $ignore_files"
	fi

	$PKGFS_XSTOW_CMD -dir $PKGFS_DESTDIR -target $PKGFS_MASTERDIR \
		-D -i-file-in-dir share/info/dir -ignore \
		"${xstow_ignore_files}" $PKGFS_DESTDIR/$pkgname-$version
	if [ "$?" -ne 0 ]; then
		exit 1
	else
		$rm_cmd -f $PKGFS_DESTDIR/$pkgname-$version/share/info/dir
		echo "==> Removed \`$pkg' symlinks from master directory."
	fi

	installed_tmpl_handler unregister $pkgname $version

	xstow_ignore_files="$real_xstow_ignore"
}

#
# Recursive function that founds dependencies in all required
# packages.
#
add_dependency_tolist()
{
	local curpkg="$1"

	[ -z "$curpkg" ] && return 1
	[ -n "$prev_pkg" ] && curpkg=$prev_pkg

	for i in $($db_cmd -V btree $PKGFS_BUILD_DEPS_DB ${curpkg%-[0-9]*.*}); do
		#
		# Check if dep already installed.
		#
		if [ -r "$PKGFS_REGPKG_DB" ]; then
			check_installed_tmpl $i ${i##[aA-zZ]*-}
			#
			# If dep is already installed, put it on the
			# installed deps list and continue.
			#
			if [ "$?" -eq 0 ]; then
				installed_deps_list="$i $installed_deps_list"
				continue
			fi

			deps_list="$i $deps_list"
			[ -n "$prev_pkg" ] && unset prev_pkg
			#
			# Check if dependency needs more deps.
			#
			check_build_depends_tmpl ${i%-[0-9]*.*}
			if [ "$?" -eq 0 ]; then
				add_dependency_tolist $i
				prev_pkg="$i"
			fi
		fi
	done
}

#
# Removes duplicate deps in the installed or not installed list.
#
find_dupdeps_inlist()
{
	local action="$1"
	local tmp_list=
	local dup=

	[ -z "$action" ] && return 1

	case "$action" in
	installed)
		list=$installed_deps_list
		;;
	notinstalled)
		list=$deps_list
		;;
	*)
		return 1
		;;
	esac

	for f in $list; do
		if [ -z "$tmp_list" ]; then
			tmp_list="$f"
		else
			for i in $tmp_list; do
				[ "$f" = "$i" ] && dup=yes
			done

			[ -z "$dup" ] && tmp_list="$tmp_list $f"
			unset dup
		fi
	done

	case "$action" in
	installed)
		installed_deps_list="$tmp_list"
		;;
	notinstalled)
		deps_list="$tmp_list"
		;;
	*)
		return 1
		;;
	esac
}

#
# Installs all dependencies required by a package.
#
install_dependency_tmpl()
{
	local pkg="$1"
	deps_list=
	installed_deps_list=

	[ -z "$pkg" ] && return 1

	doing_deps=true

	add_dependency_tolist $pkg
	find_dupdeps_inlist installed
	find_dupdeps_inlist notinstalled

	echo "==> Required dependencies for $(basename $pkg):"
	for i in ${installed_deps_list}; do
		fpkg="$($db_cmd -O '-' btree $PKGFS_REGPKG_DB ${i%-[0-9]*.*})"
		echo "	$i: found $fpkg."
	done

	for i in ${deps_list}; do
		echo "	$i: not installed."
	done

	for i in ${deps_list}; do
		# skip dup deps
		echo "=> Installing dependency: $i"
		install_tmpl ${i%-[0-9].*}
	done

	unset installed_deps_list
	unset deps_list
}

#
# Installs and stows the "xstow" package.
#
install_xstow_tmpl()
{
	[ -x "$PKGFS_XSTOW_CMD" ] && return 0

	reset_tmpl_vars
	run_file "$PKGFS_TEMPLATESDIR/xstow.tmpl"
	check_tmpl_vars $pkgname-$version
	fetch_tmpl_sources
	extract_tmpl_sources
	build_tmpl_sources
	PKGFS_XSTOW_CMD="$PKGFS_DESTDIR/$pkgname-$version/bin/xstow"
	stow_tmpl $pkgname-$version
	#
	# Continue with origin package that called us.
	#
	run_file $origin_tmpl
}

#
# Registers or unregisters a package from the db file.
#
installed_tmpl_handler()
{
	local action="$1"
	local pkg="$2"
	local version="$3"

	[ -z "$action" -o -z "$pkg" -o -z "$version" ] && return 1
	if [ "$action" = "register" ]; then
		$db_cmd -w btree $PKGFS_REGPKG_DB $pkg $version 2>&1 >/dev/null
		if [ "$?" -ne  0 ]; then
			echo -n "*** ERROR: couldn't register \`$pkg'"
			echo " in db file ***"
			exit 1
		fi
	elif [ "$action" = "unregister" ]; then
		$db_cmd -d btree $PKGFS_REGPKG_DB $pkg 2>&1 >/dev/null
		if [ "$?" -ne 0 ]; then
			echo -n "*** ERROR: \`$pkg' not registered "
			echo "in db file? ***"
			exit 1
		fi
	else
		return 1
	fi
}

#
# Checks the registered pkgs db file and returns 0 if a pkg that satisfies
# the minimal required version if there, or 1 otherwise.
#
check_installed_tmpl()
{
	local pkg="$1"
	local reqver="$2"
	local iver=

	[ -z "$pkg" -o -z "$reqver" ] && return 1

	run_file $PKGFS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl

	reqver="$(echo $reqver | $sed_cmd 's|\.||g;s|[aA-zZ]||g')"

	$db_cmd -K btree $PKGFS_REGPKG_DB $pkgname 2>&1 >/dev/null
	if [ "$?" -eq 0 ]; then
		#
		# Package is installed, let's check the version.
		#
		iver="$($db_cmd -V btree $PKGFS_REGPKG_DB $pkgname)"
		if [ -n "$iver" ]; then
			#
			# As shell only supports decimal arith expressions,
			# we simply remove anything except the numbers.
			# It's not optimal and may fail, but it is enough
			# for now.
			#
			iver="$(echo $iver | $sed_cmd 's|\.||g;s|[aA-zZ]||g')"
			if [ "$iver" -eq "$reqver" \
			     -o "$iver" -gt "$reqver" ]; then
			     return 0
			fi
		fi
	fi

	return 1
}

#
# Checks the build depends db file and returns 0 if pkg has dependencies,
# otherwise returns 1.
#
check_build_depends_tmpl()
{
	local pkg="$1"

	[ -z $pkg ] && return 1
	[ ! -r $PKGFS_BUILD_DEPS_DB ] && return 1

	$db_cmd -V btree $PKGFS_BUILD_DEPS_DB ${pkg%-[0-9]*.*} 2>&1 >/dev/null
	return $?
}

#
# Installs a pkg by reading its build template file.
#
install_tmpl()
{
	local pkg=
	cur_tmpl="$PKGFS_TEMPLATESDIR/$1.tmpl"
	if [ -z "$cur_tmpl" -o ! -f "$cur_tmpl" ]; then
		echo -n "*** ERROR: invalid template file '$cur_tmpl',"
		echo " aborting ***"
		exit 1
	fi

	reset_tmpl_vars
	run_file $cur_tmpl
	pkg="$1-$version"

	#
	# If we are the originator package save the path this template in
	# other var for future use.
	#
	if [ -z "$origin_tmpl" ]; then
		origin_tmpl=$path_fixed
	fi

	#
	# Install xstow if it's not there.
	#
	install_xstow_tmpl

	#
	# Check vars for current template.
	#
	check_tmpl_vars $pkg

	#
	# Install dependencies required by this package.
	#
	check_build_depends_tmpl $pkg
	if [ "$?" -eq 0 -a -z "$doing_deps" ]; then
		install_dependency_tmpl $pkg
		#
		# At this point all required deps are installed, and
		# only remaining is the origin template; install it.
		#
		unset doing_deps
		reset_tmpl_vars
		run_file $origin_tmpl
		check_tmpl_vars $pkgname-$version
	fi

	if [ -n "$only_build" ]; then
		build_tmpl_sources
		exit 0
	fi

	#
	# Fetch, extract, stow and reset vars for a template.
	#
	fetch_tmpl_sources
	extract_tmpl_sources
	build_tmpl_sources

	#
	# Just announce that meta-template is installed and exit.
	#
	if [ "$build_style" = "meta-template" ]; then
		installed_tmpl_handler register $pkgname $version
		echo "==> Installed meta-template \`$pkg'."
		return 0
	fi

	#
	# Do not stow the pkg if requested.
	#
	[ -z "$only_install" ] && stow_tmpl $pkg
}

#
# Lists all currently installed packages.
#
list_tmpls()
{
	if [ ! -r "$PKGFS_REGPKG_DB" ]; then
		echo "=> No packages registered or missing register db file."
		exit 0
	fi

	for i in $($db_cmd -K btree $PKGFS_REGPKG_DB); do
		# Run file to get short_desc and print something useful
		run_file ${PKGFS_TEMPLATESDIR}/$i.tmpl
		echo "$i-$version        $short_desc"
		reset_tmpl_vars
	done
}

#
# Removes a currently installed package (unstow + removed from destdir).
#
remove_tmpl()
{
	local pkg="$1"

	if [ -z "$pkg" ]; then
		echo "*** ERROR: unexistent package, aborting ***"
		exit 1
	fi

	if [ ! -f "$PKGFS_TEMPLATESDIR/$pkg.tmpl" ]; then
		echo "*** ERROR: cannot find template file ***"
		exit 1
	fi

	run_file $PKGFS_TEMPLATESDIR/$pkg.tmpl

	#
	# If it's a meta-template, just unregister it from the db.
	#
	if [ "$build_style" = "meta-template" ]; then
		installed_tmpl_handler unregister $pkgname $version
		[ "$?" -eq 0 ] && \
			echo "=> Removed meta-template \`$pkg'."
		return $?
	fi

	if [ ! -d "$PKGFS_DESTDIR/$pkg-$version" ]; then
		echo "*** ERROR: cannot find package on $PKGFS_DESTDIR ***"
		exit 1
	fi

	unstow_tmpl $pkg
	$rm_cmd -rf $PKGFS_DESTDIR/$pkg-$version
	return "$?"
}

#
# main()
#
args=$(getopt bCc:efi $*)
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
		config_file_specified=yes
		PKGFS_CONFIG_FILE="$2"
		shift
		;;
	-e)
		only_extract=yes
		;;
	-f)
		only_fetch=yes
		;;
	-i)
		only_install=yes
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

#
# Check configuration vars before anyting else, and set defaults vars.
#
check_config_vars
set_defvars

# Main switch
case "$target" in
info)
	info_tmpl "$2"
	;;
install)
	install_tmpl "$2"
	;;
list)
	list_tmpls
	;;
remove)
	remove_tmpl "$2"
	;;
stow)
	stow_flag=yes
	stow_tmpl "$2"
	;;
unstow)
	unstow_tmpl "$2"
	;;
*)
	echo "*** ERROR invalid target '$target' ***"
	usage
esac

# Agur
exit 0
