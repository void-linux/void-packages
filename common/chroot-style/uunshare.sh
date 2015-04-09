#!/bin/sh
#
# This chroot script uses xbps-uunshare(8) with user_namespaces(7).
#
readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"
shift 4

if ! command -v xbps-uunshare >/dev/null 2>&1; then
	exit 1
fi

if [ -z "$MASTERDIR" -o -z "$DISTDIR" ]; then
	echo "$0 MASTERDIR/DISTDIR not set"
	exit 1
fi

exec xbps-uunshare $EXTRA_ARGS -D $DISTDIR ${HOSTDIR:+-H $HOSTDIR} $MASTERDIR $@
