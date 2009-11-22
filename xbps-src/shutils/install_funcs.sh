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
# Runs the "install" phase for a pkg. This consists in installing package
# into the destination directory.
#

strip_files()
{
	if [ ! -x /usr/bin/strip ]; then
		return 0
	fi
	[ -n "$nostrip" ] && return 0

	msg_normal "Finding binaries/libraries to strip..."
	for f in $(find ${DESTDIR} -type f); do
		case "$(file -biz $f)" in
		application/x-executable*)
			/usr/bin/strip $f && \
				echo "===> Stripped executable: $(basename $f)";;
		application/x-sharedlib*|application/x-archive*)
			/usr/bin/strip -S $f && \
				echo "===> Stripped library: $(basename $f)";;
		esac
	done
}

install_src_phase()
{
	local f i subpkg lver spkgrev saved_wrksrc

	[ -z $pkgname ] && return 1

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

	saved_wrksrc=$wrksrc
	cd $wrksrc || msg_error "can't change cwd to wrksrc!"

	# Run pre_install func.
	run_func pre_install || msg_error "pre_install stage failed!"

	msg_normal "Running install phase for $pkgname-$lver."

	# cross compilation vars.
	if [ -n "$cross_compiler" ]; then
		. $XBPS_SHUTILSDIR/cross-compilation.sh
		cross_compile_setvars
	fi

	# Type of installation: custom, make or python.
	case "$build_style" in
	custom-install)
		run_func do_install || msg_error "do_install stage failed!"
		;;
	python-module)
		. $XBPS_HELPERSDIR/python-module.sh
		run_func do_install || msg_error "python module install failed!"
		;;
	*)
		make_install $lver
		;;
	esac

	# Run post_install func.
	run_func post_install || msg_error "post_install stage failed!"

	# Remove libtool archives by default.
	if [ -z "$keep_libtool_archives" ]; then
		find ${DESTDIR} -type f -name \*.la -delete
	fi
	# Always remove perllocal.pod and .packlist files.
	if [ "$pkgname" != "perl" ]; then
		find ${DESTDIR} -type f -name perllocal.pod -delete
		find ${DESTDIR} -type f -name .packlist -delete
	fi
	# Remove empty directories by default.
	if [ -z "$keep_empty_dirs" ]; then
		find ${DESTDIR} -depth -type d -empty -delete
	fi
	# Strip bins/libs.
	if [ -z "$noarch" ]; then
		strip_files
	fi

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
		if [ -n "$revision" ]; then
			spkgrev="${subpkg}-${version}_${revision}"
		else
			spkgrev="${subpkg}-${version}"
		fi
		check_installed_pkg ${spkgrev}
		[ $? -eq 0 ] && continue

		msg_normal "Preparing ${sourcepkg} subpackage: ${subpkg}"
		if [ ! -f $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template ]; then
			msg_error "Cannot find ${subpkg} subpkg build template!"
		fi
		. $XBPS_SRCPKGDIR/${sourcepkg}/${subpkg}.template
		pkgname=${subpkg}
		set_tmpl_common_vars
		run_func do_install || \
			msg_error "$pkgname do_install stage failed!"
	done

	#
	# Remove $wrksrc if -C not specified.
	#
	if [ -d "$saved_wrksrc" -a -z "$dontrm_builddir" ]; then
		rm -rf $saved_wrksrc && \
			msg_normal "Removed $sourcepkg-$lver build directory."
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
	run_rootcmd no ${make_cmd} ${make_install_target} \
		${make_install_args} || msg_error "installing $pkgname-$lver"

	# Unset build vars.
	unset_build_vars
}
