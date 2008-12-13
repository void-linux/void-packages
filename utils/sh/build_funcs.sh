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

	[ ! -d $wrksrc ] && msg_error "unexistent build directory [$wrksrc]"

	cd $wrksrc || exit 1

	# cross compilation vars.
	if [ -n "$cross_compiler" ]; then
		. $XBPS_HELPERSDIR/cross-compilation.sh
		cross_compile_setvars
	fi

	[ -z "$make_cmd" ] && make_cmd=/usr/bin/make

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

	if [ -z "$in_chroot" ]; then
		. $XBPS_SHUTILSDIR/libtool_funcs.sh
		libtool_fixup_file
	fi

	if [ -z "$in_chroot" ]; then
		. $XBPS_SHUTILSDIR/buildvars_funcs.sh
		set_build_vars
	fi

	msg_normal "Running build phase for $pkg."

	#
	# Build package via make.
	#
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
	[ $? -ne 0 ] && msg_error "building $pkg (build phase)."

	unset makejobs

	#
	# Run pre_install helpers.
	#
	run_func pre_install

	if [ -z "$in_chroot" ]; then
		if [ -z "$libtool_fixup_la_stage" \
		     -o "$libtool_fixup_la_stage" = "postbuild" ]; then
			libtool_fixup_la_files
		fi
	fi

	# unset cross compiler vars.
	[ -n "$cross_compiler" ] && cross_compile_unsetvars

	if [ -z "$in_chroot" ]; then
		unset_build_vars
	fi

	touch -f $XBPS_BUILD_DONE
}
