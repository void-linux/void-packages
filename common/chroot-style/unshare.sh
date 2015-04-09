#!/bin/sh
#
# This chroot script uses unshare(1) with user_namespaces(7).
#
readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"

if ! command -v unshare >/dev/null 2>&1; then
	exit 1
fi

if [ -z "$XBPS_IS_UNSHARED" ]; then
	XBPS_IS_UNSHARED=1 exec unshare $EXTRA_ARGS -m -U -r -- "$0" "$@"
	exit 1
fi

shift 4

if [ -z "$MASTERDIR" -o -z "$DISTDIR" ]; then
	echo "$0 MASTERDIR/DISTDIR not set"
	exit 1
fi

for i in /dev /proc /sys; do
	mount --rbind "$i" "$MASTERDIR/$i" || exit 1
done
mount --rbind "$DISTDIR" "$MASTERDIR/void-packages" || exit 1
mount --rbind "$HOSTDIR" "$MASTERDIR/host" || exit 1
exec chroot "$MASTERDIR" "$@"
