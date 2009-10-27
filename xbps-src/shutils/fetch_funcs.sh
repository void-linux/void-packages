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
# Verifies that file's checksum downloaded matches what it's specified
# in template file.
#
verify_sha256_cksum()
{
	local file="$1"
	local origsum="$2"

	[ -z "$file" -o -z "$cksum" ] && return 1

	filesum=$(xbps-digest.static $XBPS_SRCDISTDIR/$file)
	if [ "$origsum" != "$filesum" ]; then
		msg_error "SHA256 checksum doesn't match for $file."
	fi

	msg_normal "SHA256 checksum OK for $file."
}

fetch_update_cksum()
{
	local tmpl="$XBPS_TEMPLATESDIR/$pkgname/template"
	local upcmd=$(basename $XBPS_SRCDISTDIR/$1)

	sed -i -e "s|checksum.*|checksum=$(xbps-digest.static ${upcmd})|" $tmpl
	return $?
}

#
# Downloads the distfiles and verifies checksum for all them.
#
fetch_distfiles()
{
	local pkg="$1"
	local upcksum="$2"
	local dfiles=
	local localurl=
	local dfcount=0
	local ckcount=0
	local f=

	[ -z $pkgname ] && exit 1

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	#
	# If nofetch is set in a build template, skip this phase
	# entirely and run the do_fetch() function.
	#
	if [ -n "$nofetch" ]; then
		cd ${XBPS_BUILDDIR} && run_func do_fetch
		return $?
	fi

	cd $XBPS_SRCDISTDIR || return 1
	for f in ${distfiles}; do
		curfile=$(basename $f)
		if [ -f "$XBPS_SRCDISTDIR/$curfile" ]; then
			if [ -n "$upcksum" ]; then
				fetch_update_cksum $curfile
				run_template $pkgname
			fi

			for i in ${checksum}; do
				if [ $dfcount -eq $ckcount -a -n $i ]; then
					cksum=$i
					found=yes
					break
				fi

				ckcount=$(($ckcount + 1))
			done

			if [ -z $found ]; then
				msg_error "cannot find checksum for $curfile."
			fi

			verify_sha256_cksum $curfile $cksum
			if [ $? -eq 0 ]; then
				unset cksum found
				ckcount=0
				dfcount=$(($dfcount + 1))
				continue
			fi
		fi

		msg_normal "Fetching distfile: $curfile."

		if [ -n "$distfiles" ]; then
			localurl="$f"
		else
			localurl="$url/$curfile"
		fi

		$XBPS_FETCH_CMD $localurl
		if [ $? -ne 0 ]; then
			unset localurl
			if [ ! -f $XBPS_SRCDISTDIR/$curfile ]; then
				msg_error "couldn't fetch $curfile."
			else
				msg_error "there was an error fetching $curfile."
			fi
		else
			unset localurl

			if [ -n "$upcksum" ]; then
				fetch_update_cksum $curfile
				run_template $pkgname
			fi

			#
			# XXX duplicate code.
			#
			for i in ${checksum}; do
				if [ $dfcount -eq $ckcount -a -n $i ]; then
					cksum=$i
					found=yes
					break
				fi

				ckcount=$(($ckcount + 1))
			done

			if [ -z $found ]; then
				msg_error "cannot find checksum for $curfile."
			fi

			verify_sha256_cksum $curfile $cksum
			if [ $? -eq 0 ]; then
				unset cksum found
				ckcount=0
			fi
		fi

		dfcount=$(($dfcount + 1))
	done

	unset cksum found
}
