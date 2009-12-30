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

	for f in $(echo $XBPS_COMMONVARSDIR/*.sh); do
		[ -r ${f} ] && . ${f}
	done

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
			make_cmd base_chroot register_shell keep_empty_dirs \
			make_build_target configure_script noextract nofetch \
			pre_configure pre_build pre_install build_depends \
			post_configure post_build post_install nostrip \
			make_install_target version revision essential \
			sgml_catalogs xml_catalogs xml_entries sgml_entries \
			disable_parallel_build run_depends font_dirs preserve \
			only_for_archs conf_files keep_libtool_archives \
			noarch subpackages sourcepkg gtk_iconcache_dirs \
			abi_depends api_depends triggers openrc_services \
			replaces system_accounts build_wrksrc \
			XBPS_EXTRACT_DONE XBPS_CONFIGURE_DONE \
			XBPS_BUILD_DONE XBPS_INSTALL_DONE FILESDIR DESTDIR \
			SRCPKGDESTDIR PATCHESDIR"

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

	[ -z "$pkg" ] && return 1
	[ "$pkgname" = "$pkg" ] && return 0

	for f in $(echo $XBPS_COMMONVARSDIR/*.sh); do
		[ -r ${f} ] && . ${f}
	done

	if [ -f $XBPS_SRCPKGDIR/${pkg}/template ]; then
		reset_tmpl_vars
		. $XBPS_SRCPKGDIR/${pkg}/template
		prepare_tmpl
	else
		msg_error "Cannot find $pkg build template file."
	fi

}

check_builddep_dup()
{
	local dep="$1" i

	for i in ${build_depends}; do
		[ "${i}" != "${dep}" ] && continue
		return 1
	done
}

check_rundep_dup()
{
	local dep="$1" i

	for i in ${run_depends}; do
		[ "${i}" != "${dep}" ] && continue
		return 1
	done
}

Add_dependency()
{
	local type="$1" pkgname="$2" version="$3"

	case "$type" in
		build|full|run) ;;
		*) msg_error "Unknown dependency type for $pkgname." ;;
	esac

	[ -z "$pkgname" ] && msg_error "Add_dependency: pkgname empty!"

	if [ -f $XBPS_SRCPKGDIR/${pkgname}/${pkgname}.depends ]; then
		. $XBPS_SRCPKGDIR/${pkgname}/${pkgname}.depends
	elif [ -f $XBPS_SRCPKGDIR/${pkgname}/depends ]; then
		. $XBPS_SRCPKGDIR/${pkgname}/depends
	fi

	if [ "$type" = "full" -o "$type" = "build" ]; then
		if [ -z "$version" -a -z "$api_depends" ]; then
			if check_builddep_dup "${pkgname}>=0"; then
				build_depends="${build_depends} ${pkgname}>=0"
			fi
		elif [ -z "$version" -a -n "$api_depends" ]; then
			if check_builddep_dup "${pkgname}${api_depends}"; then
				build_depends="${build_depends} ${pkgname}${api_depends}"
			fi
		else
			if check_builddep_dup "${pkgname}${version}"; then
				build_depends="${build_depends} ${pkgname}${version}"
			fi
		fi
	fi

	if [ "$type" = "full" -o "$type" = "run" ]; then
		if [ -z "$version" -a -z "$abi_depends" ]; then
			if check_rundep_dup "${pkgname}>=0"; then
				run_depends="${run_depends} ${pkgname}>=0"
			fi
		elif [ -z "$version" -a -n "$abi_depends" ]; then
			if check_rundep_dup "${pkgname}${api_depends}"; then
				run_depends="${run_depends} ${pkgname}${abi_depends}"
			fi
		else
			if check_rundep_dup "${pkgname}${version}"; then
				run_depends="${run_depends} ${pkgname}${version}"
			fi
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
	if [ "$build_style" = "meta-template" ]; then
		set_tmpl_common_vars
		return 0
	fi

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
		export PATH="$PATH:$XBPS_MASTERDIR/usr/bin"
		export PATH="$PATH:$XBPS_MASTERDIR/usr/sbin"
		export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin"
		export PATH="$PATH:/usr/local/sbin"
	fi
}

set_tmpl_common_vars()
{
	[ -z "$pkgname" ] && return 1

	FILESDIR=$XBPS_SRCPKGDIR/$pkgname/files
	PATCHESDIR=$XBPS_SRCPKGDIR/$pkgname/patches
	DESTDIR=${XBPS_DESTDIR}/${pkgname}-${version}
	if [ -z "${sourcepkg}" ]; then
		sourcepkg=${pkgname}
	fi
	SRCPKGDESTDIR=${XBPS_DESTDIR}/${sourcepkg}-${version}
}
