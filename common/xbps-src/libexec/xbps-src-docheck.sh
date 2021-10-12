#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname to build [REQUIRED]
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

XBPS_CHECK_DONE="${XBPS_STATEDIR}/${sourcepkg}_${XBPS_CROSS_BUILD}_check_done"

if [ -n "$XBPS_CROSS_BUILD" ]; then
    msg_normal "${pkgname}-${version}_${revision}: skipping check (cross build for $XBPS_CROSS_BUILD) ...\n"
    exit 0
fi

if [ -z "$XBPS_CHECK_PKGS" ]; then
    msg_normal "${pkgname}-${version}_${revision}: skipping check (XBPS_CHECK_PKGS is disabled) ...\n"
    exit 0
fi

if [ "$make_check" = no ]; then
    msg_normal "${pkgname}-${version}_${revision}: skipping check (make_check=no) ...\n"
    exit 0
fi

if [ "$make_check" = extended -a "$XBPS_CHECK_PKGS" != full ]; then
    msg_normal \
        "${pkgname}-${version}_${revision}: skipping check (make_check=extended and XBPS_CHECK_PKGS is not 'full') ...\n"
    exit 0
fi

if [ "$make_check" = ci-skip ] && [ "$XBPS_BUILD_ENVIRONMENT" = void-packages-ci ]; then
    msg_warn \
        "${pkgname}-${version}_${revision}: skipping here because of make_check=ci-skip. Tests should be run locally.\n"
    exit 0
fi

for f in $XBPS_COMMONDIR/environment/check/*.sh; do
    source_file "$f"
done

run_step check optional

touch -f $XBPS_CHECK_DONE

exit 0
