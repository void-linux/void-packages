#!/bin/sh
#-
# Copyright (c) 2010-2011 Juan Romero Pardines.
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

PKG_TMPLNAME="$1"

if [ -n "${CONFIG_FILE}" -a -r "${CONFIG_FILE}" ]; then
	. ${CONFIG_FILE}
fi

if [ -n "${MASTERDIR}" ]; then
	export XBPS_MASTERDIR="${MASTERDIR}"
fi

. ${XBPS_SHAREDIR}/shutils/init_funcs.sh

set_defvars

for f in $XBPS_SHUTILSDIR/*.sh; do
	[ -r "$f" ] && . $f
done

install_src_phase()
{
	local f i subpkg spkgrev

	[ -z $pkgname ] && return 2
	#
	# There's nothing we can do if we are a meta template.
	# Just creating the dir is enough to write the package metadata.
	#
	if [ "$build_style" = "meta-template" ]; then
		mkdir -p $XBPS_DESTDIR/$pkgname-$version
		return 0
	fi

	cd $wrksrc || msg_error "can't change cwd to wrksrc!\n"
	if [ -n "$build_wrksrc" ]; then
		cd $build_wrksrc \
			|| msg_error "can't change cwd to build_wrksrc!\n"
	fi

	# Run pre_install func.
	if [ ! -f $XBPS_PRE_INSTALL_DONE ]; then
		run_func pre_install
		[ $? -eq 0 ] && touch -f $XBPS_PRE_INSTALL_DONE
	fi

	# do_install()
	if [ -r $XBPS_HELPERSDIR/${build_style}.sh ]; then
		. $XBPS_HELPERSDIR/${build_style}.sh
	fi
	run_func do_install

	cd ${wrksrc} || msg_error "can't change cwd to wrksrc!\n"

	# Run post_install func.
	if [ ! -f $XBPS_POST_INSTALL_DONE ]; then
		run_func post_install
		[ $? -eq 0 ] && touch -f $XBPS_POST_INSTALL_DONE
	fi

	# Remove libtool archives by default.
	if [ -z "$keep_libtool_archives" ]; then
		msg_normal "$pkgver: removing libtool archives...\n"
		find ${DESTDIR} -type f -name \*.la -delete
	fi
	# Remove bytecode python generated files.
	msg_normal "$pkgver: removing python bytecode archives...\n"
	find ${DESTDIR} -type f -name \*.py[co] -delete

	# Always remove perllocal.pod and .packlist files.
	if [ "$pkgname" != "perl" ]; then
		find ${DESTDIR} -type f -name perllocal.pod -delete
		find ${DESTDIR} -type f -name .packlist -delete
	fi
	# Remove empty directories by default.
	for f in $(find ${DESTDIR} -depth -type d); do
		rmdir $f 2>/dev/null && msg_warn "removed empty dir: ${f##${DESTDIR}}\n"
	done
	#
	# Build subpackages if found.
	#
	for subpkg in ${subpackages}; do
		if [ -n "$revision" ]; then
			spkgrev="${subpkg}-${version}_${revision}"
		else
			spkgrev="${subpkg}-${version}"
		fi
		check_installed_pkg ${spkgrev}
		if [ $? -eq 0 -a -z "$BOOTSTRAP_PKG_REBUILD" ]; then
			continue
		fi
		msg_normal "$pkgver: preparing subpackage '${subpkg}'...\n"
		if [ ! -f $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find '${subpkg}' subpkg build template!\n"
		fi
		. $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template
		pkgname=${subpkg}
		set_tmpl_common_vars
		if [ ! -f ${wrksrc}/.xbps_do_install_${pkgname}_done ]; then
			run_func do_install
			if [ $? -eq 0 ]; then
				touch -f ${wrksrc}/.xbps_do_install_${pkgname}_done
			fi
		else
			msg_warn "$pkgver: skipping '$pkgname' subpkg, already installed into destdir.\n"
		fi
	done
	touch -f $XBPS_INSTALL_DONE
}

[ -z "$PKG_TMPLNAME" ] && exit 2

setup_tmpl $PKG_TMPLNAME
install_src_phase $pkgname

exit 0
