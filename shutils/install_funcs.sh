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
# Runs the "install" phase for a pkg. This consists in installing package
# into the destination directory.
#
install_src_phase()
{
	local pkg="$1"
	local f i subpkg lver spkgrev

	[ -z $pkg ] && [ -z $pkgname ] && return 1

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	#
	# There's nothing we can do if we are a meta template.
	# Just creating the dir is enough to write the package metadata.
	#
	if [ "$build_style" = "meta-template" ]; then
		mkdir -p $XBPS_DESTDIR/$pkgname-$version
		return 0
	fi

	[ ! -d $wrksrc ] && msg_error "unexistent build directory [$wrksrc]"

	cd $wrksrc || exit 1

	# Run pre_install func.
	run_func pre_install

	msg_normal "Running install phase for $pkgname-$lver."

	# cross compilation vars.
	if [ -n "$cross_compiler" ]; then
		. $XBPS_HELPERSDIR/cross-compilation.sh
		cross_compile_setvars
	fi

	if [ "$build_style" = "custom-install" ]; then
		run_func do_install
	else
		make_install $lver
	fi

	# Run post_install func.
	run_func post_install

	# Remove libtool archives from pkg destdir.
	find ${DESTDIR} -type f -name \*.la -delete

	# unset cross compiler vars.
	[ -n "$cross_compiler" ] && cross_compile_unsetvars

	msg_normal "Installed $pkgname-$lver into $XBPS_DESTDIR."

	if [ "$build_style" != "custom-install" -a -z "$distfiles" ]; then
		touch -f $XBPS_INSTALL_DONE
	fi

	#
	# Build subpackages if found.
	#
	for subpkg in ${subpackages}; do
		if [ "${pkg}" != "${sourcepkg}" ] && \
		   [ "${pkg}" != "${sourcepkg}-${subpkg}" ]; then
			continue
		fi
		if [ -n "$revision" ]; then
			spkgrev="${sourcepkg}-${subpkg}-${version}_${revision}"
		else
			spkgrev="${sourcepkg}-${subpkg}-${version}"
		fi
		check_installed_pkg ${spkgrev}
		[ $? -eq 0 ] && continue

		msg_normal "Preparing ${sourcepkg} subpackage: $sourcepkg-$subpkg"
		if [ ! -f $XBPS_TEMPLATESDIR/$pkgname/$subpkg.template ]; then
			msg_error "Cannot find subpackage template!"
		fi
		. $XBPS_TEMPLATESDIR/$pkgname/$subpkg.template
		pkgname=${sourcepkg}-${subpkg}
		set_tmpl_common_vars
		run_func do_install
		run_template ${sourcepkg}
		[ "$pkg" = "${sourcepkg}-${subpkg}" ] && break
	done
	[ -n "$subpackages" ] && setup_tmpl ${sourcepkg}

	#
	# Remove $wrksrc if -C not specified.
	#
	if [ -d "$wrksrc" -a -z "$dontrm_builddir" ]; then
		rm -rf $wrksrc
		[ $? -eq 0 ] && \
			msg_normal "Removed $pkgname-$lver build directory."
	fi
}

#
# Installs a package via 'make install ...'.
#

make_install()
{
	local lver="$1"

	if [ -z "$make_install_target" ]; then
		make_install_target="DESTDIR=${DESTDIR} install"
	fi

	[ -z "$make_cmd" ] && make_cmd=/usr/bin/make

	. $XBPS_SHUTILSDIR/buildvars_funcs.sh
	set_build_vars

	#
	# Install package via make.
	#
	run_rootcmd no ${make_cmd} ${make_install_target} ${make_install_args}
	if [ "$?" -ne 0 ]; then
		msg_error "installing $pkgname-$lver."
		exit 1
	fi

	# Replace libtool archives if requested.
	if [ -z "$in_chroot" ]; then
		if [ "$libtool_fixup_la_stage" = "postinstall" ]; then
			. $XBPS_SHUTILSDIR/libtool_funcs.sh
			libtool_fixup_la_files postinstall
		fi
	fi

	# Always remove perllocal.pod and .packlist files for
	# perl modules.
	if [ "$build_style" = "perl_module" -a "$pkgname" != "perl" ]; then
		find ${DESTDIR} -name perllocal.pod -delete
		find ${DESTDIR} -name .packlist -delete
	fi

	# Unset build vars.
	unset_build_vars
}
