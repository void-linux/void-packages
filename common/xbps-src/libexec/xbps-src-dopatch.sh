#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname [REQUIRED]
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

for f in $XBPS_COMMONDIR/environment/patch/*.sh; do
    source_file "$f"
done

XBPS_PATCH_DONE="${XBPS_STATEDIR}/${sourcepkg}_${XBPS_CROSS_BUILD}_patch_done"

if [ -f $XBPS_PATCH_DONE ]; then
    exit 0
fi

[ -d "$wrksrc" ] && cd "$wrksrc"

# Run pre-patch hooks
run_pkg_hooks pre-patch

# If template defines pre_patch(), use it.
if declare -f pre_patch >/dev/null; then
    run_func pre_patch
fi

# If template defines do_patch() use it rather than the build-style.
if declare -f do_patch >/dev/null; then
    run_func do_patch
else
    if [ -n "$build_style" ]; then
        if [ ! -r $XBPS_BUILDSTYLEDIR/${build_style}.sh ]; then
            msg_error "$pkgver: cannot find build helper $XBPS_BUILDSTYLEDIR/${build_style}.sh!\n"
        fi
        . $XBPS_BUILDSTYLEDIR/${build_style}.sh

        if declare -f do_patch >/dev/null; then
            run_func do_patch
        fi
    fi
fi

# Run do-patch hooks
run_pkg_hooks "do-patch"

# If template defines post_patch(), use it.
if declare -f post_patch >/dev/null; then
    run_func post_patch
fi

# Run post-patch hooks
run_pkg_hooks post-patch

touch -f $XBPS_PATCH_DONE

exit 0
