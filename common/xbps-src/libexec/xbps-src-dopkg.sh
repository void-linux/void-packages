#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
# 	$1 - pkgname [REQUIRED]
#	$2 - path to local repository [REQUIRED]
# 	$3 - cross-target [OPTIONAL]

if [ $# -lt 2 -o $# -gt 3 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname repository [cross-target]"
    exit 1
fi

PKGNAME="$1"
XBPS_REPOSITORY="$2"
XBPS_CROSS_BUILD="$3"

for f in $XBPS_SHUTILSDIR/*.sh; do
    . $f
done

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD

for f in $XBPS_COMMONDIR/environment/pkg/*.sh; do
    source_file "$f"
done

if [ "$sourcepkg" != "$PKGNAME" ]; then
    # Source all subpkg environment setup snippets.
    for f in ${XBPS_COMMONDIR}/environment/setup-subpkg/*.sh; do
        source_file "$f"
    done

    ${PKGNAME}_package
    pkgname=$PKGNAME
    if [ -n "$noarch" ]; then
        archs=noarch
        unset noarch
        msg_warn "deprecated property 'noarch'. Use archs=noarch instead!\n"
    fi
    if [ -n "$only_for_archs" ]; then
        archs="$only_for_archs"
        unset only_for_archs
    fi
fi

if [ -s $XBPS_MASTERDIR/.xbps_chroot_init ]; then
    export XBPS_ARCH=$(cat $XBPS_MASTERDIR/.xbps_chroot_init)
fi

# Run do-pkg hooks.
run_pkg_hooks "do-pkg"

# Run post-pkg hooks.
run_pkg_hooks post-pkg

exit 0
