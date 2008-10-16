#!/bin/sh
#
# xbps - A simple, minimal, fast and uncomplete build package system.
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
#	- Implement support for packages that need personalized installation.
#	- Implement a chroot target that builds packages as root on it, for
#	  packages that need it (setuid, setgid).
#	- Personalized scripts per template to unpack distfiles.
#	- Multiple URLs to download source distribution files, aliases, etc.
#	- More robust and fast dependency checking.
#
# Default path to configuration file, can be overriden
# via the environment or command line.
#
: ${XBPS_CONFIG_FILE:=/usr/local/etc/xbps.conf}

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
: ${touch_cmd:=/usr/bin/touch}

: ${xstow_args:=-ap}
: ${xstow_ignore_files:=perllocal.pod}	# XXX For now ignore them.

set_defvars()
{
	# Directories
	: ${XBPS_TEMPLATESDIR:=$XBPS_DISTRIBUTIONDIR/templates}
	: ${XBPS_DEPSDIR:=$XBPS_DISTRIBUTIONDIR/dependencies}
	: ${XBPS_BUILD_DEPS_DB:=$XBPS_DEPSDIR/build-depends.db}
	: ${XBPS_TMPLHELPDIR:=$XBPS_DISTRIBUTIONDIR/helper-templates}
	: ${XBPS_REGPKG_DB:=$XBPS_DESTDIR/.xbps-registered-pkgs.db}

	local DDIRS="XBPS_DEPSDIR XBPS_TEMPLATESDIR XBPS_TMPLHELPDIR"
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
$progname: [-C] [-c <config_file>] <target> [package_name]

Targets:
	build		Builds a package, only build phase is done.
	configure	Configure a package, only configure phase is done.
	extract		Extract distribution file(s) into build directory.
	fetch		Download distribution file(s).
	info		Show information about <package_name>.
	install-destdir	build + configure + install into destdir.
	install		Same than \`install-destdir´ but also stows package.
	list		Lists all currently \`stowned´ packages.
	remove		Remove package completely (unstow + remove data)
	listfiles	Lists files installed from <package_name>.
	stow		Create links in master directory.
	unstow		Remove links in master directory.

Options:
	-C	Do not remove build directory after successful installation.
	-c	Path to global configuration file:
		if not specified /usr/local/etc/xbps.conf is used.
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
# into XBPS_MASTERDIR/share/info/dir.
#
merge_infodir_tmpl()
{
	local pkgname="$1"
	local merge_info_cmd="$XBPS_MASTERDIR/bin/merge-info"

	[ -z "$pkgname" -o ! -r "$XBPS_MASTERDIR/share/info/dir" \
	     -o ! -r "$XBPS_DESTDIR/$pkgname/share/info/dir" ] && return 1

	$merge_info_cmd -d $XBPS_MASTERDIR/share/info/dir 	\
		$XBPS_DESTDIR/$pkgname/share/info/dir -o 	\
		$XBPS_MASTERDIR/share/info/dir.new
	if [ $? -ne 0 ]; then
		echo -n "*** WARNING: there was an error merging info dir from"
		echo " $pkgname, aborting ***"
		return 1
	fi

	$mv_cmd -f $XBPS_MASTERDIR/share/info/dir.new \
		$XBPS_MASTERDIR/share/info/dir
}

#
# Shows info about a template.
#
info_tmpl()
{
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
	check_build_depends_pkg $pkgname-$version
	if [ $? -eq 0 ]; then
		local list="$($db_cmd -V btree $XBPS_BUILD_DEPS_DB $pkgname)"
		echo "This package requires the following dependencies to be built:"
		for i in ${list}; do
			echo " $i"
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
		config_file_paths="$XBPS_CONFIG_FILE ./xbps.conf"
		for f in $config_file_paths; do
			[ -f $f ] && XBPS_CONFIG_FILE=$f && \
				cffound=yes && break
		done
		if [ -z "$cffound" ]; then
			echo -n "*** ERROR: config file not specified "
			echo "and not in default location or current dir ***"
			exit 1
		fi
	fi

	run_file ${XBPS_CONFIG_FILE}
	XBPS_CONFIG_FILE=$path_fixed

	if [ ! -f "$XBPS_CONFIG_FILE" ]; then
		echo -n "*** ERROR: cannot find configuration file: "
		echo	"'$XBPS_CONFIG_FILE' ***"
		exit 1
	fi

	local XBPS_VARS="XBPS_MASTERDIR XBPS_DESTDIR XBPS_BUILDDIR \
			  XBPS_SRCDISTDIR XBPS_SYSCONFDIR"

	for f in ${XBPS_VARS}; do
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
	local TMPL_VARS="pkgname distfiles configure_args configure_env \
			make_build_args make_install_args build_style	\
			short_desc maintainer long_desc checksum wrksrc	\
			patch_files make_cmd pkgconfig_override \
			make_env make_build_target configure_script \
			run_stuff_before_configure_cmd run_stuff_before_build_cmd \
			run_stuff_before_install_cmd run_stuff_after_install_cmd \
			make_install_target postinstall_helpers version \
			ignore_files tar_override_cmd xml_entries sgml_entries \
			XBPS_EXTRACT_DONE XBPS_CONFIGURE_DONE \
			XBPS_BUILD_DONE XBPS_INSTALL_DONE"

	for i in ${TMPL_VARS}; do
		eval unset "$i"
	done

	unset_build_vars
}

#
# Reads a template file and setups required variables for operations.
#
setup_tmpl()
{
	local pkg="$1"

	if [ -f "$XBPS_TEMPLATESDIR/$pkg.tmpl" ]; then
		if [ "$pkgname" != "$pkg" ]; then
			run_file $XBPS_TEMPLATESDIR/$pkg.tmpl
		fi
		prepare_tmpl
	else
		echo "*** ERROR: cannot find \`$pkg´ template file ***"
		exit 1
	fi
}

#
# Checks some vars used in templates and sets some of them required.
#
prepare_tmpl()
{
	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	REQ_VARS="pkgname distfiles version build_style"

	# Check if required vars weren't set.
	for i in ${REQ_VARS}; do
		eval val="\$$i"
		if [ -z "$val" -o -z "$i" ]; then
			echo -n	"*** ERROR: \"$i\" not set on \`$pkgname' "
			echo	"template ***"
			exit 1
		fi
	done

	unset XBPS_EXTRACT_DONE XBPS_APPLYPATCHES_DONE
	unset XBPS_CONFIGURE_DONE XBPS_BUILD_DONE XBPS_INSTALL_DONE

	[ -z "$wrksrc" ] && wrksrc="$pkgname-$version"
	wrksrc="$XBPS_BUILDDIR/$wrksrc"

	XBPS_EXTRACT_DONE="$wrksrc/.xbps_extract_done"
	XBPS_APPLYPATCHES_DONE="$wrksrc/.xbps_applypatches_done"
	XBPS_CONFIGURE_DONE="$wrksrc/.xbps_configure_done"
	XBPS_BUILD_DONE="$wrksrc/.xbps_build_done"
	XBPS_INSTALL_DONE="$wrksrc/.xbps_install_done"

	export PATH="/bin:/sbin:/usr/bin:/usr/sbin:$XBPS_MASTERDIR/bin:$XBPS_MASTERDIR/sbin"
}

#
# Extracts contents of distfiles specified in a template into
# the $wrksrc directory.
#
extract_distfiles()
{
	local pkg="$1"
	local count=
	local curfile=
	local cursufx=
	local lwrksrc=
	local ltar_cmd=

	#
	# If we are being called via the target, just extract and return.
	#
	[ -n "$pkg" -a -z "$pkgname" ] && return 1

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	for f in ${distfiles}; do
		count=$(($count + 1))
	done

	if [ $count -gt 1 ]; then
		if [ -z "$wrksrc" ]; then
			echo -n "*** ERROR: \$wrksrc must be defined with "
			echo "multiple distfiles ***"
			exit 1
		fi
		$mkdir_cmd $wrksrc
	fi

	echo "==> Extracting '$pkgname-$version' distfiles."

	if [ -n "$tar_override_cmd" ]; then
		ltar_cmd="$tar_override_cmd"
	else
		ltar_cmd="$tar_cmd"
	fi

	for f in ${distfiles}; do
		curfile=$(basename $f)
		cursufx=${curfile##*@}
		curfile=$(basename $curfile|$sed_cmd 's|@||g')

		if [ $count -gt 1 ]; then
			lwrksrc="$wrksrc/${curfile%$cursufx}"
		else
			lwrksrc="$XBPS_BUILDDIR"
		fi

		case ${cursufx} in
		.tar.bz2|.tar.gz|.tgz|.tbz)
			$ltar_cmd xfz $XBPS_SRCDISTDIR/$curfile -C $lwrksrc
			if [ $? -ne 0 ]; then
				echo -n "*** ERROR extracting \`$curfile' into "
				echo	"$lwrksrc ***"
				exit 1
			fi
			;;
		.tar)
			$ltar_cmd xf $XBPS_SRCDISTDIR/$curfile -C $lwrksrc
			if [ $? -ne 0 ]; then
				echo -n "*** ERROR extracting \`$curfile' into "
				echo	"$lwrksrc ***"
				exit 1
			fi
			;;
		.zip)
			if [ -f "$XBPS_TMPLHELPDIR/unzip-extraction.sh" ]; then
				# Save vars!
				tmpf=$curfile
				tmpsufx=$cursufx
				tmpwrksrc=$lwrksrc
				. $XBPS_TMPLHELPDIR/unzip-extraction.sh
				# Restore vars!
				curfile=$tmpf
				cursufx=$tmpsufx
				lwrksrc=$tmpwrksrc
				unset tmpf tmpsufx tmpwrksrc
			else
				echo "*** ERROR: cannot find unzip helper ***"
				exit 1
			fi

			extract_unzip $XBPS_SRCDISTDIR/$curfile $lwrksrc
			if [ $? -ne 0 ]; then
				echo -n "*** ERROR extracting \`$curfile' into "
				echo	"$lwrksrc ***"
				exit 1
			fi
			;;
		*)
			echo -n "*** ERROR: cannot guess \`$curfile' extract "
			echo	"suffix ***"
			exit 1
			;;
		esac
	done

	$touch_cmd -f $XBPS_EXTRACT_DONE
}

#
# Verifies that file's checksum downloaded matches what it's specified
# in template file.
#
verify_rmd160_cksum()
{
	local file="$1"
	local origsum="$2"

	[ -z "$file" -o -z "$cksum" ] && return 1

	filesum="$($cksum_cmd $XBPS_SRCDISTDIR/$file | $awk_cmd '{print $4}')"
	if [ "$origsum" != "$filesum" ]; then
		echo "*** ERROR: RMD160 checksum doesn't match for \`$file' ***"
		exit 1
	fi

	echo "=> checksum (RMD160) OK for \`$file'."
}

#
# Downloads the distfiles and verifies checksum for all them.
#
fetch_distfiles()
{
	local pkg="$1"
	local dfiles=
	local localurl=
	local dfcount=0
	local ckcount=0

	[ -z $pkgname ] && exit 1

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	dfiles=$(echo $distfiles | $sed_cmd 's|@||g')

	for f in ${dfiles}; do
		curfile=$(basename $f)
		if [ -f "$XBPS_SRCDISTDIR/$curfile" ]; then
			for i in ${checksum}; do
				if [ $dfcount -eq $ckcount -a -n $i ]; then
					cksum=$i
					found=yes
					break
				fi

				ckcount=$(($ckcount + 1))
			done

			if [ -z $found ]; then
				echo -n "*** ERROR: cannot find checksum for "
				echo	"$curfile ***"
				exit 1
			fi

			verify_rmd160_cksum $curfile $cksum
			if [ $? -eq 0 ]; then
				unset cksum found
				ckcount=0
				dfcount=$(($dfcount + 1))
				continue
			fi
		fi

		echo "==> Fetching distfile: \`$curfile'."

		if [ -n "$distfiles" ]; then
			localurl="$f"
		else
			localurl="$url/$curfile"
		fi


		cd $XBPS_SRCDISTDIR && $fetch_cmd $localurl
		if [ $? -ne 0 ]; then
			unset localurl
			if [ ! -f $XBPS_SRCDISTDIR/$curfile ]; then
				echo -n "*** ERROR: couldn't fetch '$curfile', "
				echo	"aborting ***"
			else
				echo -n "*** ERROR: there was an error "
				echo	"fetching '$curfile', aborting ***"
			fi
			exit 1
		else
			unset localurl
			#
			# XXX duplicate code.
			#
			for i in ${checksum}; do
				if [ $dfcount -eq $ckcount -a -n $i ]; then
					cksum=$i
					found=yes
					break
				fi

				ckcount=$(($ckcount + 1))
			done

			if [ -z $found ]; then
				echo -n "*** ERROR: cannot find checksum for "
				echo "$curfile ***"
				exit 1
			fi

			verify_rmd160_cksum $curfile $cksum
			if [ $? -eq 0 ]; then
				unset cksum found
				ckcount=0
			fi
		fi

		dfcount=$(($dfcount + 1))
	done

	unset cksum found
}

fixup_tmpl_libtool()
{
	# Ignore libtool itself
	[ "$pkgname" = "libtool" ] && return 0

	#
	# If package has a libtool file replace it with ours, so that
	# we use the master directory while relinking, all will be fine
	# once the package is stowned.
	#
	for f in $($find_cmd $wrksrc -type f -name libtool\*); do
		if [ -f $f ]; then
			$rm_cmd -f $f
			$ln_cmd -s $XBPS_MASTERDIR/bin/libtool $f
		fi
	done

	if [ -f $wrksrc/ltmain.sh ]; then
		$rm_cmd -f $wrksrc/ltmain.sh
		$ln_cmd -s $XBPS_MASTERDIR/share/libtool/config/ltmain.sh \
			$wrksrc/ltmain.sh
	fi
}

set_build_vars()
{
	LDFLAGS="-L$XBPS_MASTERDIR/lib -Wl,-R$XBPS_MASTERDIR/lib $LDFLAGS"
	LDFLAGS="-L$XBPS_DESTDIR/$pkgname-$version/lib $LDFLAGS"
	CFLAGS="$CFLAGS $XBPS_CFLAGS"
	CXXFLAGS="$CXXFLAGS $XBPS_CXXFLAGS"
	CPPFLAGS="-I$XBPS_MASTERDIR/include $CPPFLAGS"
	PKG_CONFIG="$XBPS_MASTERDIR/bin/pkg-config"

	export LDFLAGS="$LDFLAGS" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
	export CPPFLAGS="$CPPFLAGS" PKG_CONFIG="$PKG_CONFIG"
}

unset_build_vars()
{
	unset LDFLAGS CFLAGS CXXFLAGS CPPFLAGS PKG_CONFIG
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
			patch="$XBPS_TEMPLATESDIR/$i"
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
				echo -n "*** ERROR: couldn't apply patch '$i',"
				echo	" aborting ***"
				exit 1
			fi
		done
	fi

	$touch_cmd -f $XBPS_APPLYPATCHES_DONE
}

#
# Runs the "configure" phase for a pkg. This setups the Makefiles or any
# other stuff required to be able to build binaries or such.
#
configure_src_phase()
{
	local pkg="$1"

	[ -z $pkg ] && [ -z $pkgname ] && return 1

	#
	# There's nothing we can do if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ ! -d $wrksrc ]; then
		echo "*** ERROR: unexistent build directory \`$wrksrc' ***"
		exit 1
	fi

	# Apply patches if requested by template file
	[ ! -f $XBPS_APPLYPATCHES_DONE ] && apply_tmpl_patches

	echo "=> Running \`\`configure´´ phase for \`$pkgname-$version'."

	# Run stuff before configure.
	local rbcf="$XBPS_TEMPLATESDIR/$pkgname-runstuff-before-configure.sh"
	[ -f "$rbcf" ] && . $rbcf
	[ -n "$run_stuff_before_configure_cmd" ] && \
		${run_stuff_before_configure_cmd}
	unset rbcf

	# Export configure_env vars.
	for f in ${configure_env}; do
		export "$f"
	done

	set_build_vars

	[ -z "$configure_script" ] && configure_script="./configure"

	#
	# Packages using GNU autoconf
	#
	if [ "$build_style" = "gnu_configure" ]; then
		cd $wrksrc || exit 1
		#
		# Pass consistent arguments to not have unexpected
		# surprises later.
		#
		${configure_script}					\
			--prefix="$XBPS_MASTERDIR"			\
			--mandir="$XBPS_DESTDIR/$pkgname-$version/man"	\
			--infodir="$XBPS_DESTDIR/$pkgname-$version/share/info"	\
			--sysconfdir="$XBPS_SYSCONFDIR"		\
			${configure_args}

	#
	# Packages using propietary configure scripts.
	#
	elif [ "$build_style" = "configure" ]; then
		cd $wrksrc || exit 1
		${configure_script} ${configure_args}
	#
	# Packages that are perl modules and use Makefile.PL files.
	# They are all handled by the helper perl-module.sh.
	#
	elif [ "$build_style" = "perl_module" ]; then
		. $XBPS_TMPLHELPDIR/perl-module.sh
		perl_module_build $pkgname

	#
	# Packages with BSD or GNU Makefiles are easy, just skip
	# the configure stage and proceed.
	#
	elif [ "$build_style" = "bsd_makefile" -o \
	       "$build_style" = "gnu_makefile" ]; then

	       cd $wrksrc || exit 1
	#
	# Unknown build_style type won't work :-)
	#
	else
		echo "*** ERROR unknown build_style \`$build_style' ***"
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

	# Override libtool scripts if necessary
	fixup_tmpl_libtool

	$touch_cmd -f $XBPS_CONFIGURE_DONE
}

#
# Runs the "build" phase for a pkg. This builds the binaries and other
# related stuff.
#
build_src_phase()
{
	local pkgparam="$1"
	local pkg="$pkgname-$version"

	[ -z $pkgparam ] && [ -z $pkgname -o -z $version ] && return 1

        #
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ ! -d $wrksrc ]; then
		echo "*** ERROR: unexistent build directory \`$wrksrc' ***"
		exit 1
	fi

	cd $wrksrc || exit 1

	echo "=> Running \`\`build´´ phase for \`$pkg'."

	#
	# Assume BSD make if make_cmd not set in template.
	#
	if [ -z "$make_cmd" ]; then
		make_cmd="/usr/bin/make"
	fi

	#
	# Run template stuff before building.
	#
	local rbbf="$XBPS_TEMPLATESDIR/$pkgname-runstuff-before-build.sh"
	[ -f $rbbf ] && . $rbbf
	[ -n "$run_stuff_before_build_cmd" ] && ${run_stuff_before_build_cmd}
	unset rbbf

	[ -z "$make_build_target" ] && make_build_target=
	[ -n "$XBPS_MAKEJOBS" ] && makejobs="-j$XBPS_MAKEJOBS"

	# Export make_env vars.
	for f in ${make_env}; do
		export "$f"
	done

	#
	# Build package via make.
	#
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR building (make stage) \`$pkg' ***"
		exit 1
	fi

	unset makejobs

	#
	# Run template stuff before installing.
	#
	local rbif="$XBPS_TEMPLATESDIR/$pkgname-runstuff-before-install.sh"
	[ -f $rbif ] && . $rbif
	[ -n "$run_stuff_before_install_cmd" ] && \
		${run_stuff_before_install_cmd}
	unset rbif

	$touch_cmd -f $XBPS_BUILD_DONE
}

#
# Runs the "install" phase for a pkg. This consists in installing package
# into the destination directory.
#
install_src_phase()
{
	local pkg="$1"

	[ -z $pkg ] && [ -z $pkgname ] && return 1

	[ -z "$make_install_target" ] && make_install_target=install

	#
	# There's nothing we can do if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ ! -d $wrksrc ]; then
		echo "*** ERROR: unexistent build directory \`$wrksrc' ***"
		exit 1
	fi

	cd $wrksrc || exit 1

	echo "=> Running \`\`install´´ phase for: \`$pkgname-$version´."

	#
	# Install package via make.
	#
	${make_cmd} ${make_install_args} ${make_install_target} \
		prefix="$XBPS_DESTDIR/$pkgname-$version"
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR instaling \`$pkgname-$version' ***"
		exit 1
	fi

	# Unset make_env vars.
	for f in ${make_env}; do
		unset eval ${f%=*}
	done

	#
	# Run template stuff after installing.
	#
	local raif="$XBPS_TEMPLATESDIR/$pkgname-runstuff-after-install.sh"
	[ -f $raif ] && . $raif
	[ -n "$run_stuff_after_install_cmd" ] && ${run_stuff_after_install_cmd}
	unset raif

	#
	# Transform pkg-config files if requested by template.
	#
	for i in ${pkgconfig_override}; do
		local tmpf="$XBPS_DESTDIR/$pkgname-$version/lib/pkgconfig/$i"
		[ -f "$tmpf" ] && \
			[ -f $XBPS_TMPLHELPDIR/pkg-config-transform.sh ] && \
			. $XBPS_TMPLHELPDIR/pkg-config-transform.sh && \
			pkgconfig_transform_file $tmpf
	done

	# Unset build vars.
	unset_build_vars

	echo "==> Installed \`$pkgname-$version' into $XBPS_DESTDIR."

	$touch_cmd -f $XBPS_INSTALL_DONE

	#
	# Remove $wrksrc if -C not specified.
	#
	if [ -d "$wrksrc" -a -z "$dontrm_builddir" ]; then
		$rm_cmd -rf $wrksrc
		[ "$?" -eq 0 ] && \
			echo "=> Removed \`$pkgname-$version' build directory."
	fi

	cd $XBPS_BUILDDIR
}

#
# Registers or unregisters a package from the db file.
#
register_pkg_handler()
{
	local action="$1"
	local pkg="$2"
	local version="$3"

	[ -z "$action" -o -z "$pkg" -o -z "$version" ] && return 1

	if [ "$action" = "register" ]; then
		$db_cmd -w btree $XBPS_REGPKG_DB $pkg $version 2>&1 >/dev/null
		if [ "$?" -ne  0 ]; then
			echo -n "*** ERROR: couldn't register \`$pkg'"
			echo	" in db file ***"
			exit 1
		fi
	elif [ "$action" = "unregister" ]; then
		$db_cmd -d btree $XBPS_REGPKG_DB $pkg 2>&1 >/dev/null
		if [ "$?" -ne 0 ]; then
			echo -n "*** ERROR: \`$pkg' not registered "
			echo	"in db file? ***"
			exit 1
		fi
	else
		return 1
	fi
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

	for i in $($db_cmd -V btree $XBPS_BUILD_DEPS_DB ${curpkg%-[0-9]*.*}); do
		#
		# Check if dep already installed.
		#
		if [ -r "$XBPS_REGPKG_DB" ]; then
			check_installed_pkg $i ${i##[aA-zZ]*-}
			#
			# If dep is already installed, check one more time
			# if all its deps are there and continue.
			#
			if [ $? -eq 0 ]; then
				install_builddeps_required_pkg $i
				installed_deps_list="$i $installed_deps_list"
				continue
			fi

			deps_list="$i $deps_list"
			[ -n "$prev_pkg" ] && unset prev_pkg
			#
			# Check if dependency needs more deps.
			#
			check_build_depends_pkg ${i%-[0-9]*.*}
			if [ $? -eq 0 ]; then
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
install_dependencies_pkg()
{
	local pkg="$1"
	deps_list=
	installed_deps_list=

	[ -z "$pkg" ] && return 1

	doing_deps=true

	echo -n "=> Calculating dependency list for '$pkgname-$version'... "
	add_dependency_tolist $pkg
	find_dupdeps_inlist installed
	find_dupdeps_inlist notinstalled
	echo "done."

	[ -z "$deps_list" -a -z "$installed_deps_list" ] && return 0

	echo "==> Required dependencies for $(basename $pkg):"
	for i in ${installed_deps_list}; do
		fpkg="$($db_cmd -O '-' btree $XBPS_REGPKG_DB ${i%-[0-9]*.*})"
		echo "	$i: found $fpkg."
	done

	for i in ${deps_list}; do
		echo "	$i: not installed."
	done

	for i in ${deps_list}; do
		# skip dup deps
		check_installed_pkg $i ${i##[aA-zZ]*-}
		[ $? -eq 0 ] && continue
		# continue installing deps
		echo "==> Installing \`$pkg´ dependency: \`$i´."
		install_pkg ${i%-[0-9]*.*}
	done

	unset installed_deps_list
	unset deps_list
}

install_builddeps_required_pkg()
{
	local pkg="$1"

	[ -z "$pkg" ] && return 1

	for dep in $($db_cmd -V btree $XBPS_BUILD_DEPS_DB ${pkg%-[0-9]*.*}); do
		check_installed_pkg $dep ${dep##[aA-zZ]*-}
		if [ $? -ne 0 ]; then
			echo "==> Installing \`$pkg´ dependency: $dep."
			install_pkg ${dep%-[0-9]*.*}
		fi
	done
}

#
# Checks the registered pkgs db file and returns 0 if a pkg that satisfies
# the minimal required version is there, or 1 otherwise.
#
check_installed_pkg()
{
	local pkg="$1"
	local reqver="$2"
	local iver=

	[ -z "$pkg" -o -z "$reqver" -o ! -r $XBPS_REGPKG_DB ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		run_file $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	reqver="$(echo $reqver | $sed_cmd 's|[[:punct:]]||g;s|[[:alpha:]]||g')"

	$db_cmd -K btree $XBPS_REGPKG_DB $pkgname 2>&1 >/dev/null
	if [ $? -eq 0 ]; then
		#
		# Package is installed, let's check the version.
		#
		iver="$($db_cmd -V btree $XBPS_REGPKG_DB $pkgname)"
		if [ -n "$iver" ]; then
			#
			# As shell only supports decimal arith expressions,
			# we simply remove anything except the numbers.
			# It's not optimal and may fail, but it is enough
			# for now.
			#
			iver="$(echo $iver | $sed_cmd 's|[[:punct:]]||g;s|[[:alpha:]]||g')"
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
check_build_depends_pkg()
{
	local pkg="$1"

	[ -z $pkg -o ! -r $XBPS_BUILD_DEPS_DB ] && return 1

	$db_cmd -V btree $XBPS_BUILD_DEPS_DB ${pkg%-[0-9]*.*} 2>&1 >/dev/null
	return $?
}

#
# Installs a pkg by reading its build template file.
#
install_pkg()
{
	local pkg=
	local curpkgn="$1"

	local cur_tmpl="$XBPS_TEMPLATESDIR/$curpkgn.tmpl"
	if [ -z $cur_tmpl -o ! -f $cur_tmpl ]; then
		echo "*** ERROR: cannot find \`$cur_tmpl´ template file ***"
		exit 1
	fi

	reset_tmpl_vars
	run_file $cur_tmpl
	pkg="$curpkgn-$version"

	#
	# If we are the originator package save the path this template in
	# other var for future use.
	#
	[ -z "$origin_tmpl" ] && origin_tmpl=$pkgname

	#
	# Install xstow if it's not there.
	#
	install_xstow_pkg

	#
	# We are going to install a new package.
	#
	prepare_tmpl

	#
	# Install dependencies required by this package.
	#
	if [ -z "$doing_deps" ]; then
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
	fetch_distfiles

	if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
		extract_distfiles
	fi

	if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
		configure_src_phase
	fi

	if [ ! -f "$XBPS_BUILD_DONE" ]; then
		build_src_phase
	fi

	install_src_phase

	#
	# Just register meta-template and exit.
	#
	if [ "$build_style" = "meta-template" ]; then
		register_pkg_handler register $pkgname $version
		echo "==> Installed meta-template \`$pkg'."
		return 0
	fi

	#
	# Do not stow package if it wasn't requested.
	#
	[ -z "$install_destdir_target" ] && stow_pkg $pkg
}

#
# Installs and stows the "xstow" package.
#
install_xstow_pkg()
{
	[ -x "$XBPS_XSTOW_CMD" ] && return 0

	echo "=> xstow application not found, will install it now."

	reset_tmpl_vars
	setup_tmpl xstow
	fetch_distfiles

	if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
		extract_distfiles
	fi

	if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
		configure_src_phase
	fi

	if [ ! -f "$XBPS_BUILD_DONE" ]; then
		build_src_phase
	fi

	install_src_phase

	XBPS_XSTOW_CMD="$XBPS_DESTDIR/$pkgname-$version/bin/xstow"
	stow_pkg $pkgname-$version

	#
	# Continue with package that called us.
	#
	run_file $XBPS_TEMPLATESDIR/$origin_tmpl.tmpl
}

#
# Lists all currently installed packages.
#
list_pkgs()
{
	if [ ! -r "$XBPS_REGPKG_DB" ]; then
		echo "=> No packages registered or missing register db file."
		exit 0
	fi

	for i in $($db_cmd -K btree $XBPS_REGPKG_DB); do
		# Run file to get short_desc and print something useful
		run_file $XBPS_TEMPLATESDIR/$i.tmpl
		echo "$i-$version	$short_desc"
		reset_tmpl_vars
	done
}

#
# Lists files installed by a package.
#
list_pkg_files()
{
	local pkg="$1"

	if [ -z $pkg ]; then
		echo "*** ERROR: unexistent package, aborting ***"
		exit 1
	fi

	if [ ! -d "$XBPS_DESTDIR/$pkg" ]; then
		echo "*** ERROR: cannot find \`$pkg' in $XBPS_DESTDIR ***"
		exit 1
	fi

	for f in $($find_cmd $XBPS_DESTDIR/$pkg -type f -print | sort -u); do
		echo "${f##$XBPS_DESTDIR/$pkg/}"
	done
}

#
# Removes a currently installed package (unstow + removed from destdir).
#
remove_pkg()
{
	local pkg="$1"

	if [ -z "$pkg" ]; then
		echo "*** ERROR: unexistent package, aborting ***"
		exit 1
	fi

	if [ ! -f "$XBPS_TEMPLATESDIR/$pkg.tmpl" ]; then
		echo "*** ERROR: cannot find template file ***"
		exit 1
	fi

	run_file $XBPS_TEMPLATESDIR/$pkg.tmpl

	#
	# If it's a meta-template, just unregister it from the db.
	#
	if [ "$build_style" = "meta-template" ]; then
		register_pkg_handler unregister $pkgname $version
		[ $? -eq 0 ] && \
			echo "=> Removed meta-template \`$pkg'."
		return $?
	fi

	if [ ! -d "$XBPS_DESTDIR/$pkg-$version" ]; then
		echo "*** ERROR: cannot find package on $XBPS_DESTDIR ***"
		exit 1
	fi

	unstow_pkg $pkg
	$rm_cmd -rf $XBPS_DESTDIR/$pkg-$version
	return $?
}

#
# Stows a currently installed package, i.e creates the links
# on the master directory.
#
stow_pkg()
{
	local pkg="$1"
	local infodir_pkg="share/info/dir"
	local infodir_master="$XBPS_MASTERDIR/share/info/dir"
	local real_xstowargs="$xstow_args"
	local real_xstow_ignore="$xstow_ignore_files"

	[ -z "$pkg" ] && return 2

	if [ -n "$stow_flag" ]; then
		pkg=$XBPS_TEMPLATESDIR/$pkg.tmpl
		if [ "$pkgname" != "$pkg" ]; then
			run_file $pkg
		fi
		pkg=$pkgname-$version
		#
		# You cannot stow a meta-template.
		#
		[ "$build_style" = "meta-template" ] && return 0
	fi

	if [ -r "$XBPS_DESTDIR/$pkg/$infodir_pkg" ]; then
		merge_infodir_tmpl $pkg
	fi

	if [ -r "$XBPS_DESTDIR/$pkg/$infodir_pkg" \
	     -a -r "$infodir_master" ]; then
		xstow_args="$xstow_args -i-file-in-dir $infodir_pkg"
	fi

	if [ -n "$ignore_files" ]; then
		xstow_ignore_files="$xstow_ignore_files $ignore_files"
	fi

	$XBPS_XSTOW_CMD -ignore "${xstow_ignore_files}" ${xstow_args} \
		-pd-targets $XBPS_MASTERDIR \
		-dir $XBPS_DESTDIR -target $XBPS_MASTERDIR \
		$XBPS_DESTDIR/$pkg
	if [ "$?" -ne 0 ]; then
		echo "*** ERROR: couldn't create symlinks for \`$pkg' ***"
		exit 1
	else
		echo "==> Created \`$pkg' symlinks into master directory."
	fi

	register_pkg_handler register $pkgname $version

	#
	# Run template postinstall helpers if requested.
	#
	if [ "$pkgname" != "${pkg%%-$version}" ]; then
		run_file $XBPS_TEMPLATESDIR/${pkg%%-$version}.tmpl
	fi

	for i in ${postinstall_helpers}; do
		local pihf="$XBPS_TMPLHELPDIR/$i"
		[ -f "$pihf" ] && . $pihf
	done

	xstow_ignore_files="$real_xstow_ignore"
	xstow_args="$real_xstowargs"
}

#
# Unstows a currently stowned package, i.e removes its links
# from the master directory.
#
unstow_pkg()
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

	if [ "$pkgname" != "$pkg" ]; then
		run_file $XBPS_TEMPLATESDIR/$pkg.tmpl
	fi

	#
	# You cannot unstow a meta-template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ -n "$ignore_files" ]; then
		xstow_ignore_files="$xstow_ignore_files $ignore_files"
	fi

	$XBPS_XSTOW_CMD -dir $XBPS_DESTDIR -target $XBPS_MASTERDIR \
		-D -i-file-in-dir share/info/dir -ignore \
		"${xstow_ignore_files}" $XBPS_DESTDIR/$pkgname-$version
	if [ $? -ne 0 ]; then
		exit 1
	else
		$rm_cmd -f $XBPS_DESTDIR/$pkgname-$version/share/info/dir
		echo "==> Removed \`$pkg' symlinks from master directory."
	fi

	register_pkg_handler unregister $pkgname $version

	xstow_ignore_files="$real_xstow_ignore"
}

#
# main()
#
args=$(getopt Cc $*)
[ "$?" -ne 0 ] && usage

set -- $args
while [ "$#" -gt 0 ]; do
	case "$1" in
	-C)
		dontrm_builddir=yes
		;;
	-c)
		config_file_specified=yes
		XBPS_CONFIG_FILE="$2"
		shift
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
	echo "*** ERROR: missing target ***"
	usage
fi

#
# Check configuration vars before anyting else, and set defaults vars.
#
check_config_vars
set_defvars

# Main switch
case "$target" in
build)
	setup_tmpl $2
	fetch_distfiles $2
	if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
		extract_distfiles $2
	fi

	if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
		configure_src_phase $2
	fi
	build_src_phase $2
	;;
configure)
	setup_tmpl $2
	fetch_distfiles $2
	if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
		extract_distfiles $2
	fi
	configure_src_phase $2
	;;
extract)
	setup_tmpl $2
	fetch_distfiles $2
	extract_distfiles $2
	;;
fetch)
	setup_tmpl $2
	fetch_distfiles $2
	;;
info)
	setup_tmpl $2
	info_tmpl $2
	;;
install-destdir)
	install_destdir_target=yes
	install_pkg $2
	;;
install)
	install_pkg $2
	;;
list)
	list_pkgs
	;;
listfiles)
	list_pkg_files $2
	;;
remove)
	remove_pkg $2
	;;
stow)
	stow_flag=yes
	setup_tmpl $2
	stow_pkg $2
	;;
unstow)
	setup_tmpl $2
	unstow_pkg $2
	;;
*)
	echo "*** ERROR: invalid target \`$target' ***"
	usage
esac

# Agur
exit 0
