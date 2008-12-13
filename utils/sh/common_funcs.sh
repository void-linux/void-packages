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
# Common functions for xbps.
#
run_func()
{
	func="$1"

	[ -z "$func" ] && return 1

	type -t $func | grep -q 'function'
	[ $? -eq 0 ] && $func
}

run_rootcmd()
{
	local lenv=

	[ -n "$in_chroot" ] && unset fakeroot_cmd

	lenv="XBPS_DESTDIR=$XBPS_DESTDIR"
	lenv="XBPS_DISTRIBUTIONDIR=$XBPS_DISTRIBUTIONDIR $lenv"
	env ${lenv} ${fakeroot_cmd} $@
}

msg_error()
{
	[ -z "$1" ] && return 1

	if [ -n "$in_chroot" ]; then
		echo "[chroot] => ERROR: $1"
	else
		echo "=> ERROR: $1"
	fi

	exit 1
}

msg_warn()
{
	[ -z "$1" ] && return 1

	if [ -n "$in_chroot" ]; then
		echo "[chroot] => WARNING: $1"
	else
		echo "=> WARNING: $1"
	fi
}

msg_normal()
{
	[ -z "$1" ] && return 1

	if [ -n "$in_chroot" ]; then
		echo "[chroot] => $1"
	else
		echo "=> $1"
	fi
}
