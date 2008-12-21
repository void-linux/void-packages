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
# Functions to fixup libtool archives while building packages
# required by xbps-base-chroot, not within the chroot.
#
libtool_fixup_file()
{
	local hldirf="hardcode_libdir_flag_spec"

	[ "$pkgname" = "libtool" -o ! -f $wrksrc/libtool ] && return 0
	[ -n "$no_libtool_fixup" ] && return 0

	sed -i -e "s|^$hldirf=.*|$hldirf=\"-Wl,-rpath /usr/lib\"|g" \
		$wrksrc/libtool
}

libtool_fixup_la_files()
{
	local f=
	local postinstall="$1"
	local where=

	# Ignore libtool itself
	[ "$pkgname" = "libtool" ] && return 0

	[ ! -f "$wrksrc/libtool" -o ! -f "$wrksrc/ltmain.sh" ] && return 0

	#
	# Replace hardcoded or incorrect paths with correct ones.
	#
	if [ -z "$postinstall" ]; then
		where="$wrksrc"
	else
		where="$XBPS_DESTDIR/$pkgname-$version"
	fi

	for f in $(find $where -type f -name \*.la*); do
		if [ -f $f ]; then
			msg_normal "Fixing up libtool archive: ${f##$where/}."
			sed -i	-e "s|\/..\/lib||g;s|\/\/lib|/usr/lib|g" \
				-e "s|$XBPS_MASTERDIR||g;s|$wrksrc||g" \
				-e "s|$where||g" $f
			awk '{ if (/^ dependency_libs/) {gsub("/usr[^]*lib","lib");}print}' \
				$f > $f.in && mv $f.in $f
		fi
	done
}
