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
# Runs the "configure" phase for a pkg. This setups the Makefiles or any
# other stuff required to be able to build binaries or such.
#
export CONFIGURE_SHARED_ARGS="--prefix=/usr --sysconfdir=/etc \
	--infodir=/usr/share/info --mandir=/usr/share/man \
	--localstatedir=/var"

configure_src_phase()
{
	local f rval

	[ -z $pkgname ] && return 1

	# Skip this phase for meta-template style builds.
	[ -n "$build_style" -a "$build_style" = "meta-template" ] && return 0

	cd $wrksrc || msg_error "unexistent build directory [$wrksrc].\n"

	# Run pre_configure func.
	if [ ! -f $XBPS_PRECONFIGURE_DONE ]; then
		run_func pre_configure
		[ $? -eq 0 ] && touch -f $XBPS_PRECONFIGURE_DONE
	fi

	cd $wrksrc || return 1
	if [ -n "$build_wrksrc" ]; then
		cd $build_wrksrc || return 1
	fi

	if [ -r $XBPS_HELPERSDIR/${build_style}.sh ]; then
		. $XBPS_HELPERSDIR/${build_style}.sh
	fi
	# run do_configure()
	run_func do_configure
	rval=$?

	# Run post_configure func.
	if [ ! -f $XBPS_POSTCONFIGURE_DONE ]; then
		run_func post_configure
		[ $? -eq 0 ] && touch -f $XBPS_POSTCONFIGURE_DONE
	fi

	[ "$rval" -eq 0 ] && touch -f $XBPS_CONFIGURE_DONE

	return 0
}
