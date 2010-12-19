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
# Common functions for xbps.
#
run_func_error()
{
	local lver func="$1"

	remove_pkgdestdir_sighandler ${pkgname}

	if [ -n "${revision}" ]; then
		lver="${version}_${revision}"
	else    
		lver="${version}"
	fi

	msg_error "'${pkgname}-${lver}': '$func' phase didn't complete due to errors or SIGINT!\n"
}

remove_pkgdestdir_sighandler()
{
	local lver subpkg _pkgname="$1"

	setup_tmpl ${_pkgname}
	[ -z "$sourcepkg" ] && return 0

	if [ -n "${revision}" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	# If there is any problem in the middle of writting the metadata,
	# just remove all files from destdir of pkg.

	for subpkg in ${subpackages}; do
		if [ -d "$XBPS_DESTDIR/${subpkg}-${version%_*}" ]; then
			rm -rf "$XBPS_DESTDIR/${subpkg}-${version%_*}"
		fi
		if [ -f ${wrksrc}/.xbps_do_install_${subpkg}_done ]; then
			rm -f ${wrksrc}/.xbps_do_install_${subpkg}_done
		fi
	done

	if [ -d "$XBPS_DESTDIR/${sourcepkg}-${version%_*}" ]; then
		rm -rf "$XBPS_DESTDIR/${sourcepkg}-${version%_*}"
	fi
	msg_red "'${sourcepkg}-${lver}': removed files from DESTDIR...\n"
}

var_is_a_function()
{
	local func="$1"
	local func_result

	func_result=$(mktemp -t xbps_src_run_func.XXXXXX)
	type $func > $func_result 2>&1
	if $(grep -q 'function' $func_result); then
		rm -f $func_result
		return 1
	fi

	rm -f $func_result
	return 0
}	

run_func()
{
	local func="$1"
	local lver rval logpipe logfile

	[ -z "$func" ] && return 1

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	var_is_a_function $func
	if [ $? -eq 1 ]; then
		logpipe=/tmp/logpipe.$$
		if [ -d "${wrksrc}" ]; then
			logfile=${wrksrc}/.xbps_${func}.log
		else
			logfile=$(mktemp -t xbps_${func}_${pkgname}.log.XXXXXXXX)
		fi
		mkfifo "$logpipe"
		exec 3>&1
		tee "$logfile" < "$logpipe" &
		exec 1>"$logpipe" 2>"$logpipe"
		set -e
		trap "run_func_error $func" 0
		msg_normal "'$pkgname-$lver': running $func phase...\n"
		$func 2>&1
		set +e
		trap '' 0
		exec 1>&3 2>&3 3>&-
		rm -f "$logpipe"
		return 0
	fi
	return 255 # function not found.
}

msg_red()
{
	# error messages in bold/red
	printf "\033[1m\033[31m"
	if [ -n "$in_chroot" ]; then
		printf "[chroot] => ERROR: $@"
	else
		printf "=> ERROR: $@"
	fi
	printf "\033[m"
}

msg_error()
{
	msg_red "$@"
	exit 1
}

msg_error_nochroot()
{
	printf "\033[1m\033[31m"
	printf "=> ERROR: $@"
	printf "\033[m"

	exit 1
}

msg_warn()
{
	# warn messages in bold/yellow
	printf "\033[1m\033[33m"
	if [ -n "$in_chroot" ]; then
		printf "[chroot] => WARNING: $@"
	else
		printf "=> WARNING: $@"
	fi
	printf "\033[m"
}

msg_warn_nochroot()
{
	printf "\033[1m\033[33m"
	printf "=> WARNING: $@"
	printf "\033[m"
}

msg_normal()
{
	# normal messages in bold
	printf "\033[1m"
	if [ -n "$in_chroot" ]; then
		printf "[chroot] => $@"
	else
		printf "=> $@"
	fi
	printf "\033[m"
}

msg_normal_append()
{
	printf "\033[1m$@\033[m"
}
