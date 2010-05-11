#-
# Copyright (c) 2008-2010 Juan Romero Pardines.
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
# Functions to set some env vars required to build the packages
# required by the xbps-base-chroot package.
#

set_build_vars()
{
	local LDLIBPATH

	if [ -z "$in_chroot" ]; then
		SAVE_LDLIBPATH=$LD_LIBRARY_PATH
		if [ -d /usr/lib/libfakeroot ]; then
			LDLIBPATH="/usr/lib/libfakeroot:$XBPS_MASTERDIR/usr/lib"
		else
			LDLIBPATH="$XBPS_MASTERDIR/usr/lib"
		fi
		PKG_CONFIG="$XBPS_MASTERDIR/usr/bin/pkg-config"
		PKG_CONFIG_LIBDIR="$XBPS_MASTERDIR/usr/lib/pkgconfig"
		LDFLAGS="-L$XBPS_MASTERDIR/usr/lib"
		CPPFLAGS="-I$XBPS_MASTERDIR/usr/include $CPPFLAGS"
		
		export CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
		export LD_LIBRARY_PATH="$LDLIBPATH"
		export PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"
		export PKG_CONFIG="$PKG_CONFIG"
	else
		PKG_CONFIG="/usr/bin/pkg-config"
		PKG_CONFIG_LIBDIR="/usr/lib/pkgconfig"
	fi
	CFLAGS="$CFLAGS $XBPS_CFLAGS"
	CXXFLAGS="$CXXFLAGS $XBPS_CXXFLAGS"

	export PKG_CONFIG="$PKG_CONFIG" PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
		CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS"
}

unset_build_vars()
{
	if [ -z "$in_chroot" ]; then
		unset LDFLAGS CPPFLAGS LD_LIBRARY_PATH
		export LD_LIBRARY_PATH=$SAVE_LDLIBPATH
	fi
	unset PKG_CONFIG PKG_CONFIG_LIBDIR CFLAGS CXXFLAGS
}
