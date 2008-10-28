#!/bin/bash
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
#	- Personalized scripts per template to unpack distfiles.
#	- Multiple URLs to download source distribution files, aliases, etc.
#	- More robust and fast dependency checking.
#
# Default path to configuration file, can be overriden
# via the environment or command line.
#
: ${XBPS_CONFIG_FILE:=/etc/xbps.conf}

: ${progname:=$(basename $0)}
: ${fetch_cmd:=wget}
: ${xbps_machine:=$(uname -m)}
: ${grep_cmd:=/bin/grep}

usage()
{
	cat << _EOF
$progname: [-C] [-c <config_file>] <target> [package_name]

Targets:
	build		Builds a package, only build phase is done.
	chroot		Enters to the chroot in masterdir.
	configure	Configure a package, only configure phase is done.
	extract		Extract distribution file(s) into build directory.
	fetch		Download distribution file(s).
	info		Show information about <package_name>.
	install-destdir	build + configure + install into destdir.
	install		install-destdir + stow.
	list		Lists all currently installed packages.
	listfiles	Lists files installed from <package_name>.
	remove		Remove package completely (destdir + masterdir).
	stow		Copy files from destdir/<pkgname> into masterdir.
	unstow		Remove <pkgname> files from masterdir.

Options:
	-C	Do not remove build directory after successful installation.
	-c	Path to global configuration file:
		if not specified /etc/xbps.conf is used.
_EOF
	exit 1
}

set_defvars()
{
	local i=

	# Directories
	: ${XBPS_TEMPLATESDIR:=$XBPS_DISTRIBUTIONDIR/templates}
	: ${XBPS_TMPLHELPDIR:=$XBPS_DISTRIBUTIONDIR/helper-templates}
	: ${XBPS_PKGDB_FPATH:=$XBPS_DESTDIR/.xbps-pkgdb.plist}
	: ${XBPS_UTILSDIR:=$XBPS_DISTRIBUTIONDIR/utils}
	: ${XBPS_DIGEST_CMD:=$XBPS_UTILSDIR/xbps-digest}
	: ${XBPS_PKGDB_CMD:=$XBPS_UTILSDIR/xbps-pkgdb}

	local DDIRS="XBPS_TEMPLATESDIR XBPS_TMPLHELPDIR XBPS_UTILSDIR"
	for i in ${DDIRS}; do
		eval val="\$$i"
		if [ ! -d "$val" ]; then
			echo "**** ERROR: cannot find $i, aborting ***"
			exit 1
		fi
	done

	XBPS_PKGDB_CMD="env XBPS_PKGDB_FPATH=$XBPS_PKGDB_FPATH $XBPS_PKGDB_CMD"
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
		orig="$(pwd)/${orig%/}"
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

run_func()
{
	func="$1"

	[ -z "$func" ] && return 1

	type -t $func | grep -q 'function'
	[ $? -eq 0 ] && $func
}

msg_error()
{
	[ -z "$1" ] && return 1

	if [ -n "$in_chroot" ]; then
		echo "[chroot] *** ERROR: $1 ***"
	else
		echo "*** ERROR: $1 ***"
	fi
}

msg_warn()
{
	[ -z "$1" ] && return 1

	if [ -n "$in_chroot" ]; then
		echo "[chroot] *** WARNING: $1 ***"
	else
		echo "*** WARNING: $1 ***"
	fi
}

msg_normal()
{
	[ -z "$1" ] && return 1

	if [ -n "$in_chroot" ]; then
		echo "[chroot] ==> $1"
	else
		echo "==> $1"
	fi
}

#
# Shows info about a template.
#
info_tmpl()
{
	local i=

	echo "pkgname:	$pkgname"
	echo "version:	$version"
	for i in "${distfiles}"; do
		[ -n "$i" ] && i=$(echo $i|sed s'|@||g') && \
			echo "distfile:	$i"
	done
	[ -n $checksum ] && echo "checksum:	$checksum"
	echo "maintainer:	$maintainer"
	echo "build_style:	$build_style"
	echo "short_desc:	$short_desc"
	echo "$long_desc"
	echo
	check_build_depends_pkg $pkgname-$version
	if [ $? -eq 0 ]; then
		echo "This package requires the following dependencies to be built:"
		for i in ${build_depends}; do
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
	local f=

	if [ -z "$config_file_specified" ]; then
		config_file_paths="$XBPS_CONFIG_FILE ./xbps.conf"
		for f in $config_file_paths; do
			[ -f $f ] && XBPS_CONFIG_FILE=$f && \
				cffound=yes && break
		done
		if [ -z "$cffound" ]; then
			msg_error "cannot find a config file"
			exit 1
		fi
	fi

	run_file ${XBPS_CONFIG_FILE}
	XBPS_CONFIG_FILE=$path_fixed

	if [ ! -f "$XBPS_CONFIG_FILE" ]; then
		msg_error "cannot find configuration file: $XBPS_CONFIG_FILE"
		exit 1
	fi

	local XBPS_VARS="XBPS_MASTERDIR XBPS_DESTDIR XBPS_BUILDDIR \
			 XBPS_SRCDISTDIR"

	for f in ${XBPS_VARS}; do
		eval val="\$$f"
		if [ -z "$val" ]; then
			msg_error "'$f' not set in configuration file"
			exit 1
		fi

		if [ ! -d "$val" ]; then
			mkdir "$val"
			if [ "$?" -ne 0 ]; then
				msg_error "couldn't create '$f' directory"
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
	local v=
	local TMPL_VARS="pkgname distfiles configure_args configure_env \
			make_build_args make_install_args build_style	\
			short_desc maintainer long_desc checksum wrksrc	\
			patch_files make_cmd base_package base_chroot \
			make_env make_build_target configure_script \
			pre_configure pre_build pre_install post_install \
			postinstall_helpers make_install_target version \
			ignore_files tar_override_cmd xml_entries sgml_entries \
			build_depends libtool_fixup_la_stage no_fixup_libtool \
			disable_parallel_build \
			XBPS_EXTRACT_DONE XBPS_CONFIGURE_DONE \
			XBPS_BUILD_DONE XBPS_INSTALL_DONE"

	for v in ${TMPL_VARS}; do
		eval unset "$v"
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
		msg_error "cannot find $pkg template file"
		exit 1
	fi
}

#
# Checks some vars used in templates and sets some of them required.
#
prepare_tmpl()
{
	local i=

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	REQ_VARS="pkgname distfiles version build_style"

	# Check if required vars weren't set.
	for i in ${REQ_VARS}; do
		eval val="\$$i"
		if [ -z "$val" -o -z "$i" ]; then
			msg_error "\"$i\" not set on $pkgname template"
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

	if [ -z "$in_chroot" ]; then
		export PATH="$XBPS_MASTERDIR/bin:$XBPS_MASTERDIR/sbin"
		export PATH="$PATH:$XBPS_MASTERDIR/usr/bin:$XBPS_MASTERDIR/usr/sbin"
	fi
	export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin"
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
	local f=

	[ -f $XBPS_EXTRACT_DONE ] && return 0

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
			msg_error "\$wrksrc must be defined with multiple distfiles"
			exit 1
		fi
		mkdir $wrksrc
	fi

	msg_normal "Extracting '$pkgname-$version' distfile(s)."

	if [ -n "$tar_override_cmd" ]; then
		ltar_cmd="$tar_override_cmd"
	else
		ltar_cmd="tar"
	fi

	for f in ${distfiles}; do
		curfile=$(basename $f)
		cursufx=${curfile##*@}
		curfile=$(basename $curfile|sed 's|@||g')

		if [ $count -gt 1 ]; then
			lwrksrc="$wrksrc/${curfile%$cursufx}"
		else
			lwrksrc="$XBPS_BUILDDIR"
		fi

		case ${cursufx} in
		.tar.bz2|.tbz)
			$ltar_cmd xfj $XBPS_SRCDISTDIR/$curfile -C $lwrksrc
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $lwrksrc"
				exit 1
			fi
			;;
		.tar.gz|.tgz)
			$ltar_cmd xfz $XBPS_SRCDISTDIR/$curfile -C $lwrksrc
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $lwrksrc"
				exit 1
			fi
			;;
		.tar)
			$ltar_cmd xf $XBPS_SRCDISTDIR/$curfile -C $lwrksrc
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $lwrksrc"
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
				msg_error "cannot find unzip helper"
				exit 1
			fi

			extract_unzip $XBPS_SRCDISTDIR/$curfile $lwrksrc
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $lwrksrc"
				exit 1
			fi
			;;
		*)
			msg_error "cannot guess $curfile extract suffix"
			exit 1
			;;
		esac
	done

	touch -f $XBPS_EXTRACT_DONE
}

#
# Verifies that file's checksum downloaded matches what it's specified
# in template file.
#
verify_sha256_cksum()
{
	local file="$1"
	local origsum="$2"

	[ -z "$file" -o -z "$cksum" ] && return 1

	filesum=$($XBPS_DIGEST_CMD $XBPS_SRCDISTDIR/$file)
	if [ "$origsum" != "$filesum" ]; then
		msg_error "SHA256 checksum doesn't match for $file"
		exit 1
	fi

	msg_normal "SHA256 checksum OK for $file."
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
	local f=

	[ -z $pkgname ] && exit 1

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	dfiles=$(echo $distfiles | sed 's|@||g')

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
				msg_error "cannot find checksum for $curfile"
				exit 1
			fi

			verify_sha256_cksum $curfile $cksum
			if [ $? -eq 0 ]; then
				unset cksum found
				ckcount=0
				dfcount=$(($dfcount + 1))
				continue
			fi
		fi

		msg_normal "Fetching distfile: \`$curfile'."

		if [ -n "$distfiles" ]; then
			localurl="$f"
		else
			localurl="$url/$curfile"
		fi


		cd $XBPS_SRCDISTDIR && $fetch_cmd $localurl
		if [ $? -ne 0 ]; then
			unset localurl
			if [ ! -f $XBPS_SRCDISTDIR/$curfile ]; then
				msg_error "couldn't fetch '$curfile'"
			else
				msg_error "there was an error fetching '$curfile'"
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
				msg_error "cannot find checksum for $curfile"
				exit 1
			fi

			verify_sha256_cksum $curfile $cksum
			if [ $? -eq 0 ]; then
				unset cksum found
				ckcount=0
			fi
		fi

		dfcount=$(($dfcount + 1))
	done

	unset cksum found
}

libtool_fixup_file()
{
	[ "$pkgname" = "libtool" -o ! -f $wrksrc/libtool ] && return 0
	[ -n "$no_libtool_fixup" ] && return 0

	# If we are being invoked by a chroot, don't transform stuff.
	[ -n "$in_chroot" ] && return 0

	sed -i -e \
		's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec="-Wl,-rpath /usr/lib"|g' \
		$wrksrc/libtool
}

libtool_fixup_la_files()
{
	local f=
	local postinstall="$1"
	local where=

	# Ignore libtool itself
	[ "$pkgname" = "libtool" ] && return 0

	# If we are being invoked by a chroot, don't transform stuff.
	[ -n "$in_chroot" ] && return 0

	[ ! -f "$wrksrc/libtool" -o ! -f "$wrksrc/ltmain.sh" ] && return 0

	#
	# Replace hardcoded or incorrect paths with correct ones.
	#
	if [ -z "$postinstall" ]; then
		where="$wrksrc"
	else
		where="$XBPS_DESTDIR/$pkgname-$version"
	fi

	for f in $(find $where -type f -name \*.la*); do
		if [ -f $f ]; then
			msg_normal "Fixing up libtool archive: ${f##$where/}"
			sed -i	-e "s|\/..\/lib||g;s|\/\/lib|/usr/lib|g" \
				-e "s|$XBPS_MASTERDIR||g;s|$wrksrc||g" \
				-e "s|$XBPS_DESTDIR/$pkgname-$version||g" $f
			awk '{ if (/^ dependency_libs/) {gsub("/usr[^]*lib","lib");}print}' \
				$f > $f.in && mv $f.in $f
		fi
	done
}

set_build_vars()
{
	[ -n "$in_chroot" ] && return 0

	LDFLAGS="-L$XBPS_MASTERDIR/usr/lib"
	SAVE_LDLIBPATH=$LD_LIBRARY_PATH
	LD_LIBRARY_PATH="$XBPS_MASTERDIR/usr/lib"
	CFLAGS="$CFLAGS $XBPS_CFLAGS"
	CXXFLAGS="$CXXFLAGS $XBPS_CXXFLAGS"
	CPPFLAGS="-I$XBPS_MASTERDIR/usr/include $CPPFLAGS"
	PKG_CONFIG="$XBPS_MASTERDIR/usr/bin/pkg-config"
	PKG_CONFIG_LIBDIR="$XBPS_MASTERDIR/usr/lib/pkgconfig"

	export LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
	export CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
	export CPPFLAGS="$CPPFLAGS" PKG_CONFIG="$PKG_CONFIG"
	export PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"
	export LDFLAGS="$LDFLAGS"
}

unset_build_vars()
{
	[ -n "$in_chroot" ] && return 0

	unset LDFLAGS CFLAGS CXXFLAGS CPPFLAGS PKG_CONFIG LD_LIBRARY_PATH
	export LD_LIBRARY_PATH=$SAVE_LDLIBPATH
}

#
# Applies to the build directory the patches specified by a template.
#
apply_tmpl_patches()
{
	local patch=
	local i=

	# Apply some build/install patches automatically.
	if [ -f $XBPS_TEMPLATESDIR/$pkgname-fix-build.diff ]; then
		patch_files="$pkgname-fix-build.diff $patch_files"
	fi
	if [ -f $XBPS_TEMPLATESDIR/$pkgname-fix-install.diff ]; then
		patch_files="$pkgname-fix-install.diff $patch_files"
	fi

	#
	# If package needs some patches applied before building,
	# apply them now.
	#
	if [ -n "$patch_files" ]; then
		for i in ${patch_files}; do
			patch="$XBPS_TEMPLATESDIR/$i"
			if [ ! -f "$patch" ]; then
				msg_warn "unexistent patch: $i"
				continue
			fi

			cp -f $patch $wrksrc

			# Try to guess if its a compressed patch.
			if $(echo $patch|$grep_cmd -q .gz); then
				gunzip $wrksrc/$i
				patch=${i%%.gz}
			elif $(echo $patch|$grep_cmd -q .bz2); then
				bunzip2 $wrksrc/$i
				patch=${i%%.bz2}
			elif $(echo $patch|$grep_cmd -q .diff); then
				patch=$i
			else
				msg_warn "unknown patch type: $i"
				continue
			fi

			cd $wrksrc && patch -p0 < $patch 2>/dev/null
			if [ "$?" -eq 0 ]; then
				msg_normal "Patch applied: $i."
			else
				msg_error "couldn't apply patch: $i."
				exit 1
			fi
		done
	fi

	touch -f $XBPS_APPLYPATCHES_DONE
}

#
# Runs the "configure" phase for a pkg. This setups the Makefiles or any
# other stuff required to be able to build binaries or such.
#
configure_src_phase()
{
	local pkg="$1"
	local f=

	[ -z $pkg ] && [ -z $pkgname ] && return 1

	#
	# There's nothing we can do if we are a meta template or an
	# {custom,only}_install template.
	#
	[ "$build_style" = "meta-template" -o	\
	  "$build_style" = "only-install" -o	\
	  "$build_style" = "custom-install" ] && return 0

	if [ ! -d $wrksrc ]; then
		msg_error "unexistent build directory $wrksrc"
		exit 1
	fi

	# Apply patches if requested by template file
	[ ! -f $XBPS_APPLYPATCHES_DONE ] && apply_tmpl_patches

	# Run pre_configure helpers.
	run_func pre_configure

	# Export configure_env vars.
	for f in ${configure_env}; do
		export "$f"
	done

	msg_normal "Running configure phase for $pkgname-$version."

	set_build_vars

	[ -z "$configure_script" ] && configure_script="./configure"

	local _prefix=
	if [ -z "$base_package" ]; then
		_prefix=/usr
	else
		_prefix=
	fi

	cd $wrksrc || exit 1

	#
	# Packages using GNU autoconf
	#
	if [ "$build_style" = "gnu_configure" ]; then
		${configure_script}				\
			--host=${xbps_machine}-linux-gnu	\
			--build=${xbps_machine}-linux-gnu	\
			--prefix=${_prefix} --sysconfdir=/etc	\
			--infodir=$XBPS_DESTDIR/$pkgname-$version/usr/share/info \
			--mandir=$XBPS_DESTDIR/$pkgname-$version/usr/share/man \
			${configure_args}
	#
	# Packages using propietary configure scripts.
	#
	elif [ "$build_style" = "configure" ]; then
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
	       :
	#
	# Unknown build_style type won't work :-)
	#
	else
		msg_error "unknown build_style: $build_style"
		exit 1
	fi

	if [ "$build_style" != "perl_module" -a "$?" -ne 0 ]; then
		msg_error "building (configure state) $pkg"
		exit 1
	fi

	# unset configure_env vars.
	for f in ${configure_env}; do
		unset eval ${f%=*}
	done

	unset_build_vars

	touch -f $XBPS_CONFIGURE_DONE
}

#
# Runs the "build" phase for a pkg. This builds the binaries and other
# related stuff.
#
build_src_phase()
{
	local pkgparam="$1"
	local pkg="$pkgname-$version"
	local f=

	[ -z $pkgparam ] && [ -z $pkgname -o -z $version ] && return 1

        #
	# There's nothing of interest if we are a meta template or an
	# {custom,only}-install template.
	#
	[ "$build_style" = "meta-template" -o	\
	  "$build_style" = "only-install" -o	\
	  "$build_style" = "custom-install" ] && return 0

	if [ ! -d $wrksrc ]; then
		msg_error "unexistent build directory: $wrksrc"
		exit 1
	fi

	cd $wrksrc || exit 1

	#
	# Assume BSD make if make_cmd not set in template.
	#
	if [ -z "$make_cmd" ]; then
		make_cmd="/usr/bin/make"
	fi

	#
	# Run pre_build helpers.
	#
	run_func pre_build

	[ -z "$make_build_target" ] && make_build_target=
	[ -n "$XBPS_MAKEJOBS" -a -z "$disable_parallel_build" ] && \
		makejobs="-j$XBPS_MAKEJOBS"

	# Export make_env vars.
	for f in ${make_env}; do
		export "$f"
	done

	libtool_fixup_file
	set_build_vars

	msg_normal "Running build phase for $pkg."

	#
	# Build package via make.
	#
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
	if [ "$?" -ne 0 ]; then
		msg_error "building (make stage) $pkg"
		exit 1
	fi

	unset makejobs

	#
	# Run pre_install helpers.
	#
	run_func pre_install

	if [ -z "$libtool_fixup_la_stage" \
		-o "$libtool_fixup_la_stage" = "postbuild" ]; then
		libtool_fixup_la_files
	fi
	unset_build_vars

	touch -f $XBPS_BUILD_DONE
}

#
# Runs the "install" phase for a pkg. This consists in installing package
# into the destination directory.
#
install_src_phase()
{
	local pkg="$1"
	local f=
	local i=

	[ -z $pkg ] && [ -z $pkgname ] && return 1
	#
	# There's nothing we can do if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ ! -d $wrksrc ]; then
		msg_error "unexistent build directory: $wrksrc"
		exit 1
	fi

	cd $wrksrc || exit 1

	msg_normal "Running install phase for: $pkgname-$version."

	if [ "$build_style" = "custom-install" ]; then
		run_func do_install
	else
		make_install
	fi

	#
	# Run post_install helpers.
	#
	run_func post_install

	msg_normal "Installed $pkgname-$version into $XBPS_DESTDIR."

	touch -f $XBPS_INSTALL_DONE

	#
	# Remove $wrksrc if -C not specified.
	#
	if [ -d "$wrksrc" -a -z "$dontrm_builddir" ]; then
		rm -rf $wrksrc
		[ $? -eq 0 ] && \
			msg_normal "Removed $pkgname-$version build directory."
	fi
}

#
# Installs a package via 'make install ...'.
#
make_install()
{
	if [ -z "$make_install_target" ]; then
		make_install_target="install prefix=$XBPS_DESTDIR/$pkgname-$version/usr"
		make_install_target="$make_install_target sysconfdir=$XBPS_DESTDIR/$pkgname-$version/etc"
	fi

	[ -z "$make_cmd" ] && make_cmd=/usr/bin/make

	set_build_vars
	#
	# Install package via make.
	#
	${make_cmd} ${make_install_target} ${make_install_args}
	if [ "$?" -ne 0 ]; then
		msg_error "installing $pkgname-$version"
		exit 1
	fi

	# Replace libtool archives if requested.
	[ "$libtool_fixup_la_stage" = "postinstall" ] && \
		libtool_fixup_la_files "postinstall"

	# Unset make_env vars.
	for f in ${make_env}; do
		unset eval ${f%=*}
	done

	# Unset build vars.
	unset_build_vars
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
		$XBPS_PKGDB_CMD register $pkg $version
		[ $? -ne 0 ] && exit 1
	elif [ "$action" = "unregister" ]; then
		$XBPS_PKGDB_CMD unregister $pkg $version
		[ $? -ne 0 ] && exit 1
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
	local j=

	[ -z "$curpkg" ] && return 1
	[ -n "$prev_pkg" ] && curpkg=$prev_pkg

	if [ "$pkgname" != "${curpkg%-[0-9]*.*}" ]; then
		reset_tmpl_vars
		run_file $XBPS_TEMPLATESDIR/${curpkg%-[0-9]*.*}.tmpl
	fi

	for j in ${build_depends}; do
		#
		# Check if dep already installed.
		#
		check_installed_pkg $j ${j##[aA-zZ]*-}
		#
		# If dep is already installed, check one more time
		# if all its deps are there and continue.
		#
		if [ $? -eq 0 ]; then
			install_builddeps_required_pkg $j
			installed_deps_list="$j $installed_deps_list"
			continue
		fi

		deps_list="$j $deps_list"
		[ -n "$prev_pkg" ] && unset prev_pkg
		#
		# Check if dependency needs more deps.
		#
		check_build_depends_pkg ${j%-[0-9]*.*}
		if [ $? -eq 0 ]; then
			add_dependency_tolist $j
			prev_pkg="$j"
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
	local f=

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
	local i=
	deps_list=
	installed_deps_list=

	[ -z "$pkg" ] && return 1

	doing_deps=true

	echo -n "=> Calculating dependency list for $pkgname-$version... "
	add_dependency_tolist $pkg
	find_dupdeps_inlist installed
	find_dupdeps_inlist notinstalled
	echo "done."

	[ -z "$deps_list" -a -z "$installed_deps_list" ] && return 0

	msg_normal "Required dependencies for $(basename $pkg):"
	for i in ${installed_deps_list}; do
		fpkg="$($XBPS_PKGDB_CMD list|$grep_cmd -w ${i%-[0-9]*.*})"
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
		msg_normal "Installing $pkg dependency: $i."
		install_pkg ${i%-[0-9]*.*}
	done

	unset installed_deps_list
	unset deps_list
}

install_builddeps_required_pkg()
{
	local pkg="$1"
	local dep=

	[ -z "$pkg" ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		run_file $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	for dep in ${build_depends}; do
		check_installed_pkg $dep ${dep##[aA-zZ]*-}
		if [ $? -ne 0 ]; then
			msg_normal "Installing $pkg dependency: $dep."
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

	[ -z "$pkg" -o -z "$reqver" -o ! -r $XBPS_PKGDB_FPATH ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		reset_tmpl_vars
		run_file $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	reqver="$(echo $reqver | sed 's|[[:punct:]]||g;s|[[:alpha:]]||g')"

	$XBPS_PKGDB_CMD installed $pkgname
	if [ $? -eq 0 ]; then
		#
		# Package is installed, let's check the version.
		#
		iver="$($XBPS_PKGDB_CMD version $pkgname)"
		if [ -n "$iver" ]; then
			#
			# As shell only supports decimal arith expressions,
			# we simply remove anything except the numbers.
			# It's not optimal and may fail, but it is enough
			# for now.
			#
			iver="$(echo $iver | sed 's|[[:punct:]]||g;s|[[:alpha:]]||g')"
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

	[ -z $pkg ] && return 1

	if [ "$pkgname" != "${pkg%-[0-9]*.*}" ]; then
		reset_tmpl_vars
		run_file $XBPS_TEMPLATESDIR/${pkg%-[0-9]*.*}.tmpl
	fi

	if [ -n "$build_depends" ]; then
		return 0
	fi

	return 1
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
		msg_error "cannot find $cur_tmpl template file"
		exit 1
	fi

	#
	# If we are being invoked through the chroot, re-read config file
	# to get correct stuff.
	#
	if [ -n "$in_chroot" ]; then
		check_config_vars
		set_defvars
	fi

	reset_tmpl_vars
	run_file $cur_tmpl
	pkg="$curpkgn-$version"

	if [ -z "$base_chroot" -a -z "$in_chroot" ]; then
		run_file $XBPS_TMPLHELPDIR/chroot.sh
		install_chroot_pkg $curpkgn
		return $?
	fi

	#
	# If we are the originator package save the path this template in
	# other var for future use.
	#
	[ -z "$origin_tmpl" ] && origin_tmpl=$pkgname

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
		[ $? -eq 0 ] && \
			msg_normal "Installed meta-template: $pkg." && \
			return 0
		return 1
	fi

	#
	# Do not stow package if it wasn't requested.
	#
	[ -z "$install_destdir_target" ] && stow_pkg $pkg
}

#
# Lists all currently installed packages.
#
list_pkgs()
{
	local i=

	if [ ! -r "$XBPS_PKGDB_FPATH" ]; then
		echo "=> No packages registered or missing register db file."
		exit 0
	fi

	for i in $($XBPS_PKGDB_CMD list); do
		# Run file to get short_desc and print something useful
		run_file $XBPS_TEMPLATESDIR/${i%-[0-9]*.*}.tmpl
		echo "$i	$short_desc"
		reset_tmpl_vars
	done
}

#
# Lists files installed by a package.
#
list_pkg_files()
{
	local pkg="$1"
	local f="$XBPS_DESTDIR/$pkg/.xbps-filelist"
	
	if [ -z $pkg ]; then
		echo "*** ERROR: unexistent package, aborting ***"
		exit 1
	fi

	if [ ! -d "$XBPS_DESTDIR/$pkg" ]; then
		echo "*** ERROR: cannot find $pkg in $XBPS_DESTDIR ***"
		exit 1
	fi

	cat $f|sort -u
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
			echo "=> Removed meta-template: $pkg."
		return $?
	fi

	if [ ! -d "$XBPS_DESTDIR/$pkg-$version" ]; then
		echo "*** ERROR: cannot find package on $XBPS_DESTDIR ***"
		exit 1
	fi

	unstow_pkg $pkg
	rm -rf $XBPS_DESTDIR/$pkg-$version
	return $?
}

#
# Stows a package, i.e copy files from destdir into masterdir.
#
stow_pkg()
{
	local pkg="$1"
	local i=
	local flist="$XBPS_BUILDDIR/.xbps-filelist-$pkgname-$version"

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

	cd $XBPS_DESTDIR/$pkgname-$version || exit 1
	find . > $flist
	sed -i -e "s|^.$||g;s|^./||g" $flist
	cp -ar . $XBPS_MASTERDIR
	mv -f $flist $XBPS_DESTDIR/$pkgname-$version/.xbps-filelist

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
}

#
# Unstow a package, i.e removes its files from masterdir.
#
unstow_pkg()
{
	local pkg="$1"
	local real_xstow_ignore="$xstow_ignore_files"
	local f=

	if [ -z "$pkg" ]; then
		echo "*** ERROR: template wasn't specified? ***"
		exit 1
	fi

	if [ "$pkgname" != "$pkg" ]; then
		run_file $XBPS_TEMPLATESDIR/$pkg.tmpl
	fi

	#
	# You cannot unstow a meta-template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	cd $XBPS_DESTDIR/$pkgname-$version || exit 1
	[ ! -f .xbps-filelist ] && exit 1

	for f in $(cat .xbps-filelist|sort -ur); do
		if [ -f $XBPS_MASTERDIR/$f -o -h $XBPS_MASTERDIR/$f ]; then
			rm $XBPS_MASTERDIR/$f  >/dev/null 2>&1
			[ $? -eq 0 ] && echo "Removing file: $f"
		fi
	done

	for f in $(cat .xbps-filelist|sort -ur); do
		if [ -d $XBPS_MASTERDIR/$f ]; then
			rmdir $XBPS_MASTERDIR/$f >/dev/null 2>&1
			[ $? -eq 0 ] && echo "Removing directory: $f"
		fi
	done

	register_pkg_handler unregister $pkgname $version
}

#
# main()
#
while getopts "Cc:" opt; do
	case $opt in
	C)
		dontrm_builddir=yes
		;;
	c)
		config_file_specified=yes
		XBPS_CONFIG_FILE="$OPTARG"
		shift
		;;
	--)
		shift
		break
		;;
	esac
done
shift $(($OPTIND - 1))

[ $# -eq 0 -o $# -gt 4 ] && usage

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
	if [ -z "$base_chroot" -a -z "$in_chroot" ]; then
		run_file $XBPS_TMPLHELPDIR/chroot.sh
		build_chroot_pkg $2
		umount_chroot_fs
	else
		fetch_distfiles $2
		if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
			extract_distfiles $2
		fi
		if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
			configure_src_phase $2
		fi
		build_src_phase $2
	fi
	;;
chroot)
	run_file $XBPS_TMPLHELPDIR/chroot.sh
	enter_chroot
	;;
configure)
	setup_tmpl $2
	if [ -z "$base_chroot" -a -z "$in_chroot" ]; then
		run_file $XBPS_TMPLHELPDIR/chroot.sh
		configure_chroot_pkg $2
		umount_chroot_fs
	else
		fetch_distfiles $2
		if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
			extract_distfiles $2
		fi
		configure_src_phase $2
	fi
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
	echo "*** ERROR: invalid target: $target ***"
	usage
esac

# Agur
exit 0
