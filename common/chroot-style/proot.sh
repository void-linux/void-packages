#!/bin/sh
#
# This chroot script uses proot (see http://proot.me)
#
readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"
shift 4

if ! command -v proot >/dev/null 2>&1; then
	exit 1
fi

if [ -z "$MASTERDIR" -o -z "$DISTDIR" ]; then
	echo "$0 MASTERDIR/DISTDIR not set"
	exit 1
fi

exec proot -r $XBPS_MASTERDIR -w / -b $DISTDIR:/void-packages \
	${HOSTDIR:+-b $HOSTDIR:/host} -b /proc:/proc -b /dev:/dev \
	-b /sys:/sys $EXTRA_ARGS $@
