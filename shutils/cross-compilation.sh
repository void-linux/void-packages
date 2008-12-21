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
# This helper sets some required vars to be able to cross build
# packages on xbps. The target is specified in the configuration file
# and will be read any time the cross compilation flag is used.
#
[ -z "$XBPS_CROSS_TARGET" -o ! -d $XBPS_CROSS_DIR/bin ] && return 1

# Check if all required bins are there.
for bin in gcc g++ cpp ar as ranlib ld strip; do
	if [ ! -x $XBPS_CROSS_DIR/bin/$XBPS_CROSS_TARGET-${bin} ]; then
		msg_error "cross-compilation: cannot find ${bin}, aborting."
	fi
done

SAVE_PATH="$PATH"
if [ "$xbps_machine" = "x86_64" ]; then
	XBPS_CROSS_HOST="x86_64-unknown-linux-gnu"
else
	XBPS_CROSS_HOST="$xbps_machine-pc-linux-gnu"
fi

cross_compile_setvars()
{
	export GCC=$XBPS_CROSS_TARGET-gcc
	export CC=$XBPS_CROSS_TARGET-gcc
	export CXX=$XBPS_CROSS_TARGET-g++
	export CPP=$XBPS_CROSS_TARGET-cpp
	export AR=$XBPS_CROSS_TARGET-ar
	export AS=$XBPS_CROSS_TARGET-as
	export RANLIB=$XBPS_CROSS_TARGET-ranlib
	export LD=$XBPS_CROSS_TARGET-ld
	export STRIP=$XBPS_CROSS_TARGET-strip
	export PATH="$XBPS_CROSS_DIR/bin:$PATH"
}

cross_compile_unsetvars()
{
	unset GCC CC CXX CPP AR AS RANLIB LD STRIP PATH
	export PATH="$SAVE_PATH"
}

if [ "$build_style" = "gnu_configure" ]; then
	configure_args="--build=$XBPS_CROSS_HOST --host=$XBPS_CROSS_TARGET"
	configure_args="$configure_args --target=$XBPS_CROSS_TARGET"
fi
