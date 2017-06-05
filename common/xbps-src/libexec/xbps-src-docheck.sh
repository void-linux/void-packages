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

if [ -z "$XBPS_CHECK_PKGS" -o "$XBPS_CHECK_PKGS" = "0" -o "$XBPS_CHECK_PKGS" = "no" ]; then
    msg_normal "${pkgname}-${version}_${revision}: skipping check (XBPS_CHECK_PKGS is disabled) ...\n"
    exit 0
fi

for f in $XBPS_COMMONDIR/environment/check/*.sh; do
    source_file "$f"
done

cd "$wrksrc" || msg_error "$pkgver: cannot access wrksrc directory [$wrksrc]\n"
if [ -n "$build_wrksrc" ]; then
    cd $build_wrksrc || \
        msg_error "$pkgver: cannot access build_wrksrc directory [$build_wrksrc]\n"
fi

# Run do_check() if the function is defined
if declare -f do_check > /dev/null; then
    run_func do_check
else
    msg_normal "${pkgname}-${version}_${revision}: template does not have do_check() ...\n"
fi

touch -f $XBPS_CHECK_DONE

exit 0
