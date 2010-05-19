#-
# Copyright (c) 2010 Juan Romero Pardines.
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
# Check installed package versions against the source packages repository.
#
check_installed_packages()
{
	local f lpkgn lpkgver rv srcpkgver

	msg_normal "Checking for newer packages from srcpkgs, please wait..."
	for f in $(${XBPS_BIN_CMD} list|awk '{print $1}'); do
		lpkgn=$(${XBPS_PKGDB_CMD} getpkgname ${f})
		lpkgver=$(${XBPS_PKGDB_CMD} getpkgversion ${f})

		if [ ! -r ${XBPS_SRCPKGDIR}/${lpkgn}/template ]; then
			msg_warn "Installed package ${f} not available as source pkg, skipping."
			continue
		fi
		. ${XBPS_SRCPKGDIR}/${lpkgn}/template
		if [ -r ${XBPS_SRCPKGDIR}/${lpkgn}/${lpkgn}.template ]; then
			unset revision
			. ${XBPS_SRCPKGDIR}/${lpkgn}/${lpkgn}.template
		fi
		if [ -n "$revision" ]; then
			srcpkgver="${version}_${revision}"
		else
			srcpkgver="${version}"
		fi
		${XBPS_CMPVER_CMD} ${lpkgver} ${srcpkgver}
		rv=$?
		if [ $rv -eq 255 ]; then
			echo "   ${f}: newer version -> ${srcpkgver}"
		elif [ $rv -eq 1 ]; then
			echo "   ${f}: sourcepkg outdated -> ${srcpkgver}"
		else
			echo >&2 "   ${f}: already up to date."
		fi
		reset_tmpl_vars
	done
	msg_normal "done."
}
