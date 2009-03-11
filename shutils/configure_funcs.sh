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
# Runs the "configure" phase for a pkg. This setups the Makefiles or any
# other stuff required to be able to build binaries or such.
#
configure_src_phase()
{
	local pkg="$1"
	local f=

	[ -z $pkg ] && [ -z $pkgname ] && return 1

	[ ! -d $wrksrc ] && msg_error "unexistent build directory [$wrksrc]."

	# Apply patches if requested by template file
	if [ ! -f $XBPS_APPLYPATCHES_DONE ]; then
		. $XBPS_SHUTILSDIR/patch_funcs.sh
		apply_tmpl_patches
	fi

	#
	# There's nothing we can do if we are a meta template or an
	# {custom,only}_install template.
	#
	[ "$build_style" = "meta-template" -o	\
	  "$build_style" = "only-install" -o	\
	  "$build_style" = "custom-install" ] && return 0

	# cross compilation vars.
	if [ -n "$cross_compiler" ]; then
		. $XBPS_HELPERSDIR/cross-compilation.sh
		cross_compile_setvars
	fi

	# Run pre_configure helpers.
	run_func pre_configure

	# Export configure_env vars.
	for f in ${configure_env}; do
		export "$f"
	done

	msg_normal "Running configure phase for $pkgname-$version."

	[ -z "$configure_script" ] && configure_script="./configure"

	local _prefix=
	if [ -z "$base_package" ]; then
		_prefix=/usr
	else
		_prefix=
	fi

	cd $wrksrc || exit 1

	. $XBPS_SHUTILSDIR/buildvars_funcs.sh
	set_build_vars

	#
	# Packages using GNU autoconf
	#
	if [ "$build_style" = "gnu_configure" ]; then
		${configure_script}				\
			--prefix=${_prefix} --sysconfdir=/etc	\
			--infodir=${DESTDIR}/usr/share/info	\
			--mandir=${DESTDIR}/usr/share/man	\
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
		. $XBPS_HELPERSDIR/perl-module.sh
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
		msg_error "unknown build_style [$build_style]"
		exit 1
	fi

	if [ "$build_style" != "perl_module" -a "$?" -ne 0 ]; then
		msg_error "building $pkg (configure phase)."
	fi

	# unset configure_env vars.
	for f in ${configure_env}; do
		unset eval ${f%=*}
	done

	# unset cross compiler vars.
	[ -n "$cross_compiler" ] && cross_compile_unsetvars
	unset_build_vars
	touch -f $XBPS_CONFIGURE_DONE
}
