#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#   $1 - current pkgname to build [REQUIRED]
#   $2 - target pkgname (origin) to build [REQUIRED]
#   $3 - xbps target [REQUIRED]
#   $4 - cross target [OPTIONAL]

if [ $# -lt 3 -o $# -gt 4 ]; then
    echo "$(basename $0): invalid number of arguments: pkgname targetpkg target [cross-target]"
    exit 1
fi

readonly PKGNAME="$1"
readonly TARGET_PKG="$2"
readonly TARGET="$3"
readonly XBPS_CROSS_BUILD="$4"

for f in $XBPS_SHUTILSDIR/*.sh; do
    . $f
done

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD
show_pkg_build_options
check_pkg_arch $XBPS_CROSS_BUILD
install_cross_pkg $XBPS_CROSS_BUILD

# Install dependencies from binary packages
if [ "$PKGNAME" != "$TARGET_PKG" -o -z "$XBPS_SKIP_DEPS" ]; then
    install_pkg_deps $PKGNAME $TARGET_PKG pkg $XBPS_CROSS_BUILD || exit 1
fi

# Fetch distfiles after installing required dependencies,
# because some of them might be required for do_fetch().
$XBPS_LIBEXECDIR/xbps-src-dofetch.sh $PKGNAME $XBPS_CROSS_BUILD || exit 1
[ "$TARGET" = "fetch" ] && exit 0

# Fetch, extract, build and install into the destination directory.
$XBPS_LIBEXECDIR/xbps-src-doextract.sh $PKGNAME $XBPS_CROSS_BUILD || exit 1
[ "$TARGET" = "extract" ] && exit 0

# Run configure phase
$XBPS_LIBEXECDIR/xbps-src-doconfigure.sh $PKGNAME $XBPS_CROSS_BUILD || exit 1
[ "$TARGET" = "configure" ] && exit 0

# Run build phase
$XBPS_LIBEXECDIR/xbps-src-dobuild.sh $PKGNAME $XBPS_CROSS_BUILD || exit 1
[ "$TARGET" = "build" ] && exit 0

# Install pkgs into destdir.
$XBPS_LIBEXECDIR/xbps-src-doinstall.sh $sourcepkg $XBPS_CROSS_BUILD || exit 1

for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-doinstall.sh $subpkg $XBPS_CROSS_BUILD || exit 1
done
for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-prepkg.sh $subpkg $XBPS_CROSS_BUILD || exit 1
done

for subpkg in ${subpackages} ${sourcepkg}; do
    if [ "$PKGNAME" = "${subpkg}" -a "$TARGET" = "install" ]; then
        exit 0
    fi
done

# If install went ok generate the binpkgs.
for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-dopkg.sh $subpkg "$XBPS_REPOSITORY" "$XBPS_CROSS_BUILD" || exit 1
done

# pkg cleanup
if declare -f do_clean >/dev/null; then
    run_func do_clean
fi

if [ -z "$XBPS_KEEP_ALL" ]; then
    remove_pkg_autodeps
    remove_pkg_wrksrc
    remove_pkg $XBPS_CROSS_BUILD
    remove_pkg_statedir
fi

# If base-chroot not installed, install "base-files" into masterdir
# from local repository; this is the only pkg required to be able to build
# the bootstrap pkgs from scratch.
if [ -z "$CHROOT_READY" -a "$PKGNAME" = "base-files" ]; then
    msg_normal "Installing $PKGNAME into masterdir...\n"
    _log=$(mktemp --tmpdir || exit 1)
    if [ -n "$XBPS_BUILD_FORCEMODE" ]; then
        _flags="-f"
    fi
    $XBPS_INSTALL_CMD ${_flags} -y $PKGNAME >${_log} 2>&1
    if [ $? -ne 0 ]; then
        msg_red "Failed to install $PKGNAME into masterdir, see below for errors:\n"
        cat ${_log}
        rm -f ${_log}
        msg_error "Cannot continue!"
    fi
    rm -f ${_log}
fi

exit 0
