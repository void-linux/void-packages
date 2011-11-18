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

set_defvars()
{
	local DDIRS i

	XBPS_HELPERSDIR=${XBPS_SHAREDIR}/helpers
	XBPS_SHUTILSDIR=${XBPS_SHAREDIR}/shutils
	XBPS_META_PATH=$XBPS_MASTERDIR/var/db/xbps
	XBPS_PKGMETADIR=$XBPS_META_PATH/metadata
	XBPS_SRCPKGDIR=$XBPS_DISTRIBUTIONDIR/srcpkgs
	XBPS_COMMONDIR=${XBPS_DISTRIBUTIONDIR}/common

	if [ -n "$IN_CHROOT" ]; then
		XBPS_DESTDIR=/destdir
		XBPS_BUILDDIR=/builddir
	else
		XBPS_DESTDIR=$XBPS_MASTERDIR/destdir
		XBPS_BUILDDIR=$XBPS_MASTERDIR/builddir
	fi
	if [ -n "$XBPS_HOSTDIR" ]; then
		XBPS_PACKAGESDIR=$XBPS_HOSTDIR/binpkgs
		XBPS_SRCDISTDIR=$XBPS_HOSTDIR/sources
	else
		XBPS_SRCDISTDIR=$XBPS_MASTERDIR/host/sources
		XBPS_PACKAGESDIR=$XBPS_MASTERDIR/host/binpkgs
	fi
	XBPS_TRIGGERSDIR=$XBPS_SRCPKGDIR/xbps-triggers/files

	DDIRS="DISTRIBUTIONDIR TRIGGERSDIR HELPERSDIR SRCPKGDIR SHUTILSDIR COMMONDIR"
	for i in ${DDIRS}; do
		eval val="\$XBPS_$i"
		if [ ! -d "$val" ]; then
			echo "ERROR: cannot find $i at $val aborting."
			exit 1
		fi
	done

	for i in DESTDIR PACKAGESDIR BUILDDIR SRCDISTDIR; do
		eval val="\$XBPS_$i"
		if [ ! -d "$val" ]; then
			mdir=$(dirname $XBPS_MASTERDIR)
			[ -z "$IN_CHROOT" -a "$mdir" = "/" ] && continue
			mkdir -p $val
		fi
	done

	export XBPS_VERSION=$(xbps-bin.static -V|awk '{print $2}')
	case "${XBPS_VERSION}" in
	0.1[0-9].[0-9]*)
		xbps_conf="-C $XBPS_MASTERDIR/usr/local/etc/xbps"
		;;
	0.[89].[0-9]*)
		# XBPS < 0.10.0
		xbps_conf="-C $XBPS_MASTERDIR/usr/local/etc/xbps-conf.plist"
		;;
	esac
	xbps_conf="$xbps_conf -c $XBPS_MASTERDIR/host/repocache"

	export XBPS_PKGDB_CMD="xbps-uhelper.static -r $XBPS_MASTERDIR"
	export XBPS_BIN_CMD="xbps-bin.static $xbps_conf -r $XBPS_MASTERDIR"
	export XBPS_REPO_CMD="xbps-repo.static $xbps_conf -r $XBPS_MASTERDIR"
	export XBPS_DIGEST_CMD="xbps-uhelper.static digest"
	export XBPS_CMPVER_CMD="xbps-uhelper.static cmpver"
	export XBPS_FETCH_CMD="xbps-uhelper.static fetch"
}
