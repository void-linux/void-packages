#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname to configure [REQUIRED]
#	$2 - cross target [OPTIONAL]

if [ $# -lt 1 -o $# -gt 2 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname [cross-target]"
    exit 1
fi

PKGNAME="$1"
XBPS_CROSS_BUILD="$2"

for f in $XBPS_SHUTILSDIR/*.sh; do
    . $f
done

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD

XBPS_CONFIGURE_DONE="${XBPS_STATEDIR}/${sourcepkg}_${XBPS_CROSS_BUILD}_configure_done"

if [ -f $XBPS_CONFIGURE_DONE -a -z "$XBPS_BUILD_FORCEMODE" ] ||
   [ -f $XBPS_CONFIGURE_DONE -a -n "$XBPS_BUILD_FORCEMODE" -a $XBPS_TARGET != "configure" ]; then
    exit 0
fi

for f in $XBPS_COMMONDIR/environment/configure/*.sh; do
    source_file "$f"
done

run_step configure optional

touch -f $XBPS_CONFIGURE_DONE

exit 0
