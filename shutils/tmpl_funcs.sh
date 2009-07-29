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

#
# Shows info about a template.
#
info_tmpl()
{
	local i=

	echo "pkgname:	$pkgname"
	echo "version:	$version"
	[ -n "$revision" ] && echo "revision:   $revision"
	for i in "${distfiles}"; do
		[ -n "$i" ] && echo "distfile:	$i"
	done
	[ -n "$checksum" ] && echo "checksum:	$checksum"
	echo "maintainer:	$maintainer"
	echo "build_style:	$build_style"
	echo "short_desc:	$short_desc"
	echo "$long_desc"
	echo
	. $XBPS_SHUTILSDIR/builddep_funcs.sh
	run_template $pkgname
	check_build_depends_pkg
	if [ $? -eq 0 ]; then
		echo "This package requires the following dependencies to be built:"
		for i in ${build_depends}; do
			echo " $i"
		done
	fi
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
			patch_files make_cmd base_chroot register_shell \
			make_build_target configure_script noextract \
			pre_configure pre_build pre_install configure_shell \
			post_configure post_build post_install \
			make_install_target version revision essential \
			sgml_catalogs xml_catalogs xml_entries sgml_entries \
			build_depends libtool_fixup_la_stage no_fixup_libtool \
			disable_parallel_build run_depends cross_compiler \
			only_for_archs patch_args conf_files keep_dirs \
			noarch subpackages sourcepkg gtk_iconcache_dirs \
			abi_depends api_depends triggers openrc_services \
			XBPS_EXTRACT_DONE XBPS_CONFIGURE_DONE \
			XBPS_BUILD_DONE XBPS_INSTALL_DONE FILESDIR DESTDIR \
			SRCPKGDESTDIR"

	for v in ${TMPL_VARS}; do
		eval unset "$v"
	done

	. $XBPS_SHUTILSDIR/buildvars_funcs.sh
	unset_build_vars
}

#
# Reads a template file and setups required variables for operations.
#
setup_tmpl()
{
	local pkg="$1"

	[ -z "$pkg" ] && msg_error "missing package name after target."

	. $XBPS_SHUTILSDIR/tmpl_vars.sh

	if [ -f "$XBPS_TEMPLATESDIR/$pkg/template" ]; then
		if [ "$pkgname" != "$pkg" ]; then
			reset_tmpl_vars
			. $XBPS_TEMPLATESDIR/$pkg/template
		fi
		prepare_tmpl
	else
		msg_error "cannot find '$pkg' template build file."
	fi

}

Add_dependency()
{
	local type="$1"
	local pkgname="$2"
	local minver="$3"

	case "$type" in
		build|full|run) ;;
		*) msg_error "Unknown dependency type for $pkgname." ;;
	esac

	if [ -f $XBPS_TEMPLATESDIR/$pkgname/$pkgname.depends ]; then
		. $XBPS_TEMPLATESDIR/$pkgname/$pkgname.depends
	elif [ -f $XBPS_TEMPLATESDIR/$pkgname/depends ]; then
		. $XBPS_TEMPLATESDIR/$pkgname/depends
	fi

	if [ "$type" = "full" -o "$type" = "build" ]; then
		if [ -z "$minver" -a -z "$api_depends" ]; then
			build_depends="${build_depends} $pkgname-0"
		elif [ -z "$minver" -a -n "$api_depends" ]; then
			build_depends="${build_depends} $pkgname-$api_depends"
		else
			build_depends="${build_depends} $pkgname-$minver"
		fi
	fi

	if [ "$type" = "full" -o "$type" = "run" ]; then
		if [ -z "$minver" -a -z "$abi_depends" ]; then
			run_depends="${run_depends} $pkgname-0"
		elif [ -z "$minver" -a -n "$abi_depends" ]; then
			run_depends="${run_depends} $pkgname-$abi_depends"
		else
			run_depends="${run_depends} $pkgname-$minver"
		fi
	fi

	unset abi_depends api_depends
}

#
# Checks some vars used in templates and sets some of them required.
#
prepare_tmpl()
{
	local REQ_VARS i found

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	REQ_VARS="pkgname version build_style short_desc long_desc"

	# Check if required vars weren't set.
	for i in ${REQ_VARS}; do
		eval val="\$$i"
		if [ -z "$val" -o -z "$i" ]; then
			msg_error "\"$i\" not set on $pkgname template."
		fi
	done

	for i in ${only_for_archs}; do
		[ "$i" = "$xbps_machine" ] && found=si && break
	done
	if [ -n "${only_for_archs}" -a -z "$found" ]; then
		msg_error "this package is only for: ${only_for_archs}."
	fi

	unset XBPS_EXTRACT_DONE XBPS_APPLYPATCHES_DONE
	unset XBPS_CONFIGURE_DONE XBPS_BUILD_DONE XBPS_INSTALL_DONE

	[ -z "$wrksrc" ] && wrksrc="$pkgname-$version"
	wrksrc="$XBPS_BUILDDIR/$wrksrc"

	XBPS_EXTRACT_DONE="$wrksrc/.xbps_extract_done"
	XBPS_APPLYPATCHES_DONE="$wrksrc/.xbps_applypatches_done"
	XBPS_CONFIGURE_DONE="$wrksrc/.xbps_configure_done"
	XBPS_BUILD_DONE="$wrksrc/.xbps_build_done"
	XBPS_INSTALL_DONE="$wrksrc/.xbps_install_done"

	set_tmpl_common_vars

	if [ -z "$in_chroot" ]; then
		export PATH="$XBPS_MASTERDIR/bin:$XBPS_MASTERDIR/sbin"
		export PATH="$PATH:$XBPS_MASTERDIR/usr/bin:$XBPS_MASTERDIR/usr/sbin"
		export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin"
		export PATH="$PATH:/usr/local/sbin"
	fi
}

set_tmpl_common_vars()
{
	[ -z "$pkgname" ] && return 1

	FILESDIR=${XBPS_TEMPLATESDIR}/${pkgname}/files
	DESTDIR=${XBPS_DESTDIR}/${pkgname}-${version}
	if [ -z "${sourcepkg}" ]; then
		sourcepkg=${pkgname}
	fi
	SRCPKGDESTDIR=${XBPS_DESTDIR}/${sourcepkg}-${version}
}

run_template()
{
	local pkg="$1"

	if [ "$pkgname" != "$pkg" ]; then
		reset_tmpl_vars
		. $XBPS_TEMPLATESDIR/$pkg/template
		set_tmpl_common_vars
	fi
}
