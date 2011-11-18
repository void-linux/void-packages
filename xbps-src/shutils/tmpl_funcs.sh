#-
# Copyright (c) 2008-2011 Juan Romero Pardines.
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

	for f in $XBPS_COMMONDIR/*.sh; do
		[ -r ${f} ] && . ${f}
	done

	echo "pkgname:	$pkgname"
	echo "version:	$version"
	[ -n "$revision" ] && echo "revision:	$revision"
	for i in ${distfiles}; do
		[ -n "$i" ] && echo "distfiles:	$i"
	done
	for i in ${checksum}; do
		[ -n "$i" ] && echo "checksum:	$i"
	done
	[ -n "$noarch" ] && echo "noarch:		yes"
	echo "maintainer:	$maintainer"
	[ -n "$homepage" ] && echo "Upstream URL:	$homepage"
	[ -n "$license" ] && echo "License(s):	$license"
	[ -n "$build_style" ] && echo "build_style:	$build_style"
	for i in ${configure_args}; do
		[ -n "$i" ] && echo "configure_args:	$i"
	done
	echo "short_desc:	$short_desc"
	for i in ${subpackages}; do
		[ -n "$i" ] && echo "subpackages:	$i"
	done
	for i in ${conf_files}; do
		[ -n "$i" ] && echo "conf_files:	$i"
	done
	for i in ${replaces}; do
		[ -n "$i" ] && echo "replaces:	$i"
	done
	for i in ${conflicts}; do
		[ -n "$i" ] && echo "conflicts:	$i"
	done
	echo "$long_desc"
	echo
	check_build_depends_pkg
	if [ $? -eq 0 ]; then
		echo "This package requires the following build-time dependencies:"
		for i in ${build_depends}; do
			echo " $i"
		done
	fi
	if [ -n "${run_depends}" ]; then
		echo
		echo "This package requires the folloring run-time dependencies:"
		for i in ${run_depends}; do
			echo " $i"
		done
	fi
}

#
# Resets all vars used by a template.
#
reset_tmpl_vars()
{
	local TMPL_VARS="pkgname distfiles configure_args strip_cmd \
			make_build_args make_install_args build_style	\
			short_desc maintainer long_desc checksum wrksrc	\
			make_cmd bootstrap register_shell \
			make_build_target configure_script noextract nofetch \
			build_depends nostrip nonfree \
			make_install_target version revision patch_args \
			sgml_catalogs xml_catalogs xml_entries sgml_entries \
			disable_parallel_build run_depends font_dirs preserve \
			only_for_archs conf_files keep_libtool_archives \
			noarch subpackages sourcepkg gtk_iconcache_dirs \
			abi_depends api_depends triggers make_dirs \
			replaces system_accounts system_groups provides \
			build_wrksrc create_wrksrc broken_as_needed pkgver \
			ignore_vdeps_dir noverifyrdeps conflicts dkms_modules \
			gconf_entries gconf_schemas stow_copy stow_copy_files \
			pycompile_dirs pycompile_module systemd_services  \
			homepage license kernel_hooks_version makejobs \
			SUBPKG XBPS_EXTRACT_DONE XBPS_CONFIGURE_DONE \
			XBPS_BUILD_DONE XBPS_INSTALL_DONE FILESDIR DESTDIR \
			SRCPKGDESTDIR PATCHESDIR CFLAGS CXXFLAGS CPPFLAGS \
			CC CXX LDFLAGS LD_LIBRARY_PATH"

	local TMPL_FUNCS="pre_configure pre_build pre_install do_build \
			  do_install do_configure post_configure post_build \
			  post_install do_fetch pre_remove post_remove \
			  post_stow post_extract"

	eval unset -v "$TMPL_VARS"
	eval unset -f "$TMPL_FUNCS"
}

#
# Reads a template file and setups required variables for operations.
#
setup_tmpl()
{
	local pkg="$1"

	[ -z "$pkg" ] && return 1

	if [ "$pkgname" = "$pkg" ]; then
		[ -n "$DESTDIR" ] && return 0
	fi

	for f in $XBPS_COMMONDIR/*.sh; do
		[ -r ${f} ] && . ${f}
	done

	if [ -f $XBPS_SRCPKGDIR/${pkg}/template ]; then
		reset_tmpl_vars
		. $XBPS_SRCPKGDIR/${pkg}/template
		prepare_tmpl
	else
		msg_error "Cannot find $pkg build template file.\n"
	fi

}

setup_subpkg_tmpl()
{
	local f

	[ -z "$1" ] && return 1

	if [ -r "$XBPS_SRCPKGDIR/$1/$1.template" ]; then
		setup_tmpl $1
		unset run_depends build_depends
		. $XBPS_SRCPKGDIR/$1/$1.template
		for f in ${subpackages}; do
			[ "$f" != "$1" ] && continue
			pkgname=$f
			set_tmpl_common_vars
			SUBPKG=1
			break
		done
	else
		setup_tmpl $1
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

dependency_version()
{
	local type="$1" pkgn="$2"

	if [ -f $XBPS_SRCPKGDIR/${pkgn}/${pkgn}.depends ]; then
		. $XBPS_SRCPKGDIR/${pkgn}/${pkgn}.depends
	elif [ -f $XBPS_SRCPKGDIR/${pkgn}/depends ]; then
		. $XBPS_SRCPKGDIR/${pkgn}/depends
	fi

	if [ "$type" = "build" ]; then
		if [ -z "$api_depends" ]; then
			echo "${pkgn}>=0"
		else
			echo "${pkgn}${api_depends}"
		fi
	elif [ "$type" = "run" ]; then
		if [ -z "$abi_depends" ]; then
			echo "${pkgn}>=0"
		else
			echo "${pkgn}${abi_depends}"
		fi
	fi

	unset abi_depends api_depends
}

Add_dependency()
{
	local type="$1" pkgn="$2" ver="$3"

	case "$type" in
		build|full|run) ;;
		*) msg_error "[$pkgname] Unknown dependency type for $pkgn.\n" ;;
	esac

	[ -z "$pkgn" ] && msg_error "[$pkgname] Add_dependency: pkgname empty!\n"

	if [ -f $XBPS_SRCPKGDIR/${pkgn}/${pkgn}.depends ]; then
		. $XBPS_SRCPKGDIR/${pkgn}/${pkgn}.depends
	elif [ -f $XBPS_SRCPKGDIR/${pkgn}/depends ]; then
		. $XBPS_SRCPKGDIR/${pkgn}/depends
	fi

	if [ "$type" = "full" -o "$type" = "build" ]; then
		if [ -z "$ver" -a -z "$api_depends" ]; then
			if check_builddep_dup "${pkgn}>=0"; then
				build_depends="${build_depends} ${pkgn}>=0"
			fi
		elif [ -z "$ver" -a -n "$api_depends" ]; then
			if check_builddep_dup "${pkgn}${api_depends}"; then
				build_depends="${build_depends} ${pkgn}${api_depends}"
			fi
		else
			if check_builddep_dup "${pkgn}${version}"; then
				build_depends="${build_depends} ${pkgn}${ver}"
			fi
		fi
	fi

	if [ "$type" = "full" -o "$type" = "run" ]; then
		if [ -z "$ver" -a -z "$abi_depends" ]; then
			if check_rundep_dup "${pkgn}>=0"; then
				run_depends="${run_depends} ${pkgn}>=0"
			fi
		elif [ -z "$ver" -a -n "$abi_depends" ]; then
			if check_rundep_dup "${pkgn}${api_depends}"; then
				run_depends="${run_depends} ${pkgn}${abi_depends}"
			fi
		else
			if check_rundep_dup "${pkgn}${ver}"; then
				run_depends="${run_depends} ${pkgn}${ver}"
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

	REQ_VARS="pkgname version short_desc long_desc"

	if [ -n "$build_style" -a "$build_style" = "meta-template" ]; then
		nofetch=yes
		noextract=yes
	fi

	# Check if required vars weren't set.
	for i in ${REQ_VARS}; do
		eval val="\$$i"
		if [ -z "$val" -o -z "$i" ]; then
			msg_error "\"$i\" not set on $pkgname template.\n"
		fi
	done

	if [ -n "$only_for_archs" ]; then
		if $(echo "$only_for_archs"|grep -q "$XBPS_MACHINE"); then
			found=1
		fi
	fi
	if [ -n "${only_for_archs}" -a -z "$found" ]; then
		msg_error "$pkgname: this package cannot be built on $XBPS_MACHINE.\n"
	fi

	unset XBPS_EXTRACT_DONE XBPS_APPLYPATCHES_DONE
	unset XBPS_CONFIGURE_DONE XBPS_BUILD_DONE XBPS_INSTALL_DONE

	[ -z "$wrksrc" ] && wrksrc="$pkgname-$version"
	wrksrc="$XBPS_BUILDDIR/$wrksrc"

	XBPS_FETCH_DONE="$wrksrc/.xbps_fetch_done"
	XBPS_EXTRACT_DONE="$wrksrc/.xbps_extract_done"
	XBPS_APPLYPATCHES_DONE="$wrksrc/.xbps_applypatches_done"
	XBPS_CONFIGURE_DONE="$wrksrc/.xbps_configure_done"
	XBPS_PRECONFIGURE_DONE="$wrksrc/.xbps_pre_configure_done"
	XBPS_POSTCONFIGURE_DONE="$wrksrc/.xbps_post_configure_done"
	XBPS_BUILD_DONE="$wrksrc/.xbps_build_done"
	XBPS_PRE_BUILD_DONE="$wrksrc/.xbps_pre_build_done"
	XBPS_POST_BUILD_DONE="$wrksrc/.xbps_post_build_done"
	XBPS_INSTALL_DONE="$wrksrc/.xbps_install_done"
	XBPS_PRE_INSTALL_DONE="$wrksrc/.xbps_pre_install_done"
	XBPS_POST_INSTALL_DONE="$wrksrc/.xbps_post_install_done"

	set_tmpl_common_vars
}

remove_tmpl_wrksrc()
{
	local lwrksrc="$1"

	if [ ! -d "$lwrksrc" ]; then
		return 0
	fi

	msg_normal "$pkgver: cleaning build directory...\n"
	rm -rf $lwrksrc
	return $?
}

set_tmpl_common_vars()
{
	local cflags cxxflags cppflags ldflags

	[ -z "$pkgname" ] && return 1

	if [ -n "$revision" ]; then
		pkgver="${pkgname}-${version}_${revision}"
	else
		pkgver="${pkgname}-${version}"
	fi

	. $XBPS_SHUTILSDIR/install_files.sh

	if [ -n "$BOOTSTRAP_PKG_REBUILD" ]; then
		unset bootstrap
	fi

	FILESDIR=$XBPS_SRCPKGDIR/$pkgname/files
	PATCHESDIR=$XBPS_SRCPKGDIR/$pkgname/patches
	DESTDIR=${XBPS_DESTDIR}/${pkgname}-${version}
	if [ -z "${sourcepkg}" ]; then
		sourcepkg=${pkgname}
	fi
	SRCPKGDESTDIR=${XBPS_DESTDIR}/${sourcepkg}-${version}

	[ -n "$XBPS_CFLAGS" ] && cflags="$XBPS_CFLAGS"
	[ -n "$CFLAGS" ] && cflags="$cflags $CFLAGS"
	[ -n "$XBPS_CXXFLAGS" ] && cxxflags="$XBPS_CXXFLAGS"
	[ -n "$CXXFLAGS" ] && cxxflags="$cxxflags $CXXFLAGS"
	[ -n "$XBPS_CPPFLAGS" ] && cppflags="$XBPS_CPPFLAGS"
	[ -n "$CPPFLAGS" ] && cppflags="$cppflags $CPPFLAGS"
	[ -n "$XBPS_LDFLAGS" ] && ldflags="$XBPS_LDFLAGS"
	[ -n "$LDFLAGS" ] && ldflags="$ldflags $LDFLAGS"

	[ -n "$cflags" ] && export CFLAGS="$cflags"
	[ -n "$cxxflags" ] && export CXXFLAGS="$cxxflags"
	[ -n "$cppflags" ] && export CPPFLAGS="$cppflags"
	[ -n "$ldflags" ] && export LDFLAGS="$ldflags"

	if [ -n "$broken_as_needed" -a -n "$XBPS_LDFLAGS" ]; then
		export LDFLAGS="$(echo $LDFLAGS|sed -e "s|-Wl,--as-needed||g")"
	fi

	if [ -z "$IN_CHROOT" ]; then
		export CPPFLAGS="-I$XBPS_MASTERDIR/usr/include"
		if [ -d /usr/lib/libfakeroot ]; then
			LDLIBPATH="/usr/lib/libfakeroot:$XBPS_MASTERDIR/usr/lib"
		else
			LDLIBPATH="$XBPS_MASTERDIR/usr/lib"
		fi
		if [ -n "$BUILD_32BIT" ]; then
			# Force gcc multilib to emit 32bit binaries.
			export CC="gcc -m32"
			export CXX="g++ -m32"
			# Export default 32bit directories.
			LDLIBPATH="$LDLIBPATH:/lib32:/usr/lib32"
			LDFLAGS="-L/lib32 -L/usr/lib32"
		fi
		export LDFLAGS="$LDFLAGS -L$XBPS_MASTERDIR/usr/lib"
		export LD_LIBRARY_PATH="$LDLIBPATH"
	fi
}
