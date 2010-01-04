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
# Extracts contents of distfiles specified in a template into
# the $wrksrc directory.
#
extract_distfiles()
{
	local pkg="$1" curfile cursufx f lver

	[ -f $XBPS_EXTRACT_DONE ] && return 0
	[ -z "$in_chroot" -a ! -w $XBPS_BUILDDIR ] && \
		msg_error "can't extract distfile(s) (permission denied)"

	#
	# If we are being called via the target, just extract and return.
	#
	[ -n "$pkg" -a -z "$pkgname" ] && return 1

	#
	# There's nothing of interest if we are a meta template.
	#
	[ "$build_style" = "meta-template" ] && return 0

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi
	#
	# If noextract is set, do a "fake extraction".
	#
	if [ -z "$distfiles" -o -n "$noextract" ]; then
		mkdir $wrksrc
		touch -f $XBPS_EXTRACT_DONE
		return 0
	fi

	if [ -n "$create_wrksrc" ]; then
		mkdir -p ${wrksrc} || return 1
	fi

	msg_normal "Extracting $pkgname-$lver distfile(s)."

	for f in ${distfiles}; do
		curfile=$(basename $f)

		if $(echo $f|grep -q '.tar.lzma'); then
			cursufx="txz"
		elif $(echo $f|grep -q '.tar.xz'); then
			cursufx="txz"
		elif $(echo $f|grep -q '.txz'); then
			cursufx="txz"
		elif $(echo $f|grep -q '.tar.bz2'); then
			cursufx="tbz"
		elif $(echo $f|grep -q '.tbz'); then
			cursufx="tbz"
		elif $(echo $f|grep -q '.tar.gz'); then
			cursufx="tgz"
		elif $(echo $f|grep -q '.tgz'); then
			cursufx="tgz"
		elif $(echo $f|grep -q '.gz'); then
			cursufx="gz"
		elif $(echo $f|grep -q '.bz2'); then
			cursufx="bz2"
		elif $(echo $f|grep -q '.tar'); then
			cursufx="tar"
		elif $(echo $f|grep -q '.zip'); then
			cursufx="zip"
		else
			msg_error "unknown distfile suffix for $curfile."
		fi

		if [ -n "$create_wrksrc" ]; then
			extractdir="$wrksrc"
		else
			extractdir="$XBPS_BUILDDIR"
		fi

		case ${cursufx} in
		txz)
			if [ ! -x $XBPS_MASTERDIR/usr/bin/xz ]; then
				msg_error "cannot find xz for extraction."
			fi
			tar xfJ $XBPS_SRCDISTDIR/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $XBPS_BUILDDIR."
			fi
			;;
		tbz)
			tar xfj $XBPS_SRCDISTDIR/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $XBPS_BUILDDIR."
			fi
			;;
		tgz)
			tar xfz $XBPS_SRCDISTDIR/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $XBPS_BUILDDIR."
			fi
			;;
		gz|bz2)
			cp -f $XBPS_SRCDISTDIR/$curfile $extractdir
			if [ "$cursufx" = ".gz" ]; then
				cd $XBPS_BUILDDIR && gunzip $curfile
			else
				cd $XBPS_BUILDDIR && bunzip2 $curfile
			fi
			;;
		tar)
			tar xf $XBPS_SRCDISTDIR/$curfile -C $extractdir
			if [ $? -ne 0 ]; then
				msg_error "extracting $curfile into $XBPS_BUILDDIR."
			fi
			;;
		zip)
			if [ -x $XBPS_MASTERDIR/usr/bin/unzip ]; then
				$XBPS_MASTERDIR/usr/bin/unzip \
					-q -x $XBPS_SRCDISTDIR/$curfile \
					-d $extractdir
				if [ $? -ne 0 ]; then
					msg_error "extracting $curfile into $XBPS_BUILDDIR."
				fi
			else
				msg_error "cannot find unzip bin for extraction"
			fi
			;;
		*)
			msg_error "cannot guess $curfile extract suffix. ($cursufx)"
			;;
		esac
	done

	touch -f $XBPS_EXTRACT_DONE
}
