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
# Runs the "build" phase for a pkg. This builds the binaries and other
# related stuff.
#
do_make_build()
{
	#
	# Build package via make.
	#
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
}

build_src_phase()
{
	local pkg="$pkgname-$version" pkgparam="$1" f lver

	[ -z $pkgparam ] && [ -z $pkgname -o -z $version ] && return 1

        #
	# Skip this phase for meta-template and only-install style builds.
	#
	[ "$build_style" = "meta-template" -o	\
	  "$build_style" = "only-install" ] && return 0

	[ ! -d $wrksrc ] && msg_error "unexistent build directory [$wrksrc]\n"

	cd $wrksrc || return 1
	if [ -n "$build_wrksrc" ]; then
		cd $build_wrksrc || return 1
	fi

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
		pkg="${pkg}_${revision}"
	else
		lver="${version}"
	fi

	if [ "$build_style" = "python-module" ]; then
		make_cmd="python"
		make_build_args="setup.py build"
	else
		[ -z "$make_cmd" ] && make_cmd=make
		[ -n "$XBPS_MAKEJOBS" -a -z "$disable_parallel_build" ] && \
			makejobs="-j$XBPS_MAKEJOBS"
	fi
	# Run pre_build func.
	if [ ! -f $XBPS_PRE_BUILD_DONE ]; then
		run_func pre_build
		if [ $? -eq 0 ]; then
			msg_normal "'$pkgname-$lver': pre_build phase done.\n"
			touch -f $XBPS_PRE_BUILD_DONE
		fi
	fi

	# Disable -Wl,--as-needed if requested!
	if [ -n "$broken_as_needed" -n "$XBPS_LDFLAGS" ]; then
		export XBPS_LDFLAGS="$(echo $XBPS_LDFLAGS|sed -e "s|-Wl,--as-needed||g")"
		export LDFLAGS="$XBPS_LDFLAGS $LDFLAGS"
	fi

	if [ "$build_style" = "custom-install" ]; then
		run_func do_build
	else
		run_func do_make_build
	fi

	msg_normal "'$pkgname-$lver': build phase done.\n"

	# Run post_build func.
	if [ ! -f $XBPS_POST_BUILD_DONE ]; then
		run_func post_build
		if [ $? -eq 0 ]; then
			msg_normal "'$pkgname-l$ver': post_build phase done.\n"
			touch -f $XBPS_POST_BUILD_DONE
		fi
	fi

	unset makejobs

	touch -f $XBPS_BUILD_DONE
}
