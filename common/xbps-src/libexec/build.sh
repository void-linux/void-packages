#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#   $1 - current pkgname to build [REQUIRED]
#   $2 - target pkgname (origin) to build [REQUIRED]
#   $3 - xbps target [REQUIRED]
#   $4 - cross target [OPTIONAL]
#   $5 - internal [OPTIONAL]

if [ $# -lt 3 -o $# -gt 5 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname targetpkg target [cross-target]"
    exit 1
fi

readonly PKGNAME="$1"
readonly XBPS_TARGET_PKG="$2"
readonly XBPS_TARGET="$3"
readonly XBPS_CROSS_BUILD="$4"
readonly XBPS_CROSS_PREPARE="$5"

export XBPS_TARGET

for f in $XBPS_SHUTILSDIR/*.sh; do
    . $f
done

last="${XBPS_DEPENDS_CHAIN##*,}"
case "$XBPS_DEPENDS_CHAIN" in
    *,$last,*)
        msg_error "Build-time cyclic dependency$last,${XBPS_DEPENDS_CHAIN##*,$last,} detected.\n"
esac

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD
readonly SOURCEPKG="$sourcepkg"

check_existing_pkg

show_pkg_build_options
check_pkg_arch $XBPS_CROSS_BUILD

if [ -z "$XBPS_CROSS_PREPARE" ]; then
    prepare_cross_sysroot $XBPS_CROSS_BUILD || exit $?
fi
# Install dependencies from binary packages
if [ "$PKGNAME" != "$XBPS_TARGET_PKG" -o -z "$XBPS_SKIP_DEPS" ]; then
    install_pkg_deps $PKGNAME $XBPS_TARGET_PKG pkg $XBPS_CROSS_BUILD $XBPS_CROSS_PREPARE || exit $?
fi

if [ "$XBPS_CROSS_BUILD" ]; then
    install_cross_pkg $XBPS_CROSS_BUILD || exit $?
fi

# Fetch distfiles after installing required dependencies,
# because some of them might be required for do_fetch().
$XBPS_LIBEXECDIR/xbps-src-dofetch.sh $SOURCEPKG $XBPS_CROSS_BUILD || exit 1
[ "$XBPS_TARGET" = "fetch" ] && exit 0

# Fetch, extract, build and install into the destination directory.
$XBPS_LIBEXECDIR/xbps-src-doextract.sh $SOURCEPKG $XBPS_CROSS_BUILD || exit 1
[ "$XBPS_TARGET" = "extract" ] && exit 0

# Run patch phrase
$XBPS_LIBEXECDIR/xbps-src-dopatch.sh $SOURCEPKG $XBPS_CROSS_BUILD || exit 1
[ "$XBPS_TARGET" = "patch" ] && exit 0

# Run configure phase
$XBPS_LIBEXECDIR/xbps-src-doconfigure.sh $SOURCEPKG $XBPS_CROSS_BUILD || exit 1
[ "$XBPS_TARGET" = "configure" ] && exit 0

# Run build phase
$XBPS_LIBEXECDIR/xbps-src-dobuild.sh $SOURCEPKG $XBPS_CROSS_BUILD || exit 1
[ "$XBPS_TARGET" = "build" ] && exit 0

# Run check phase
$XBPS_LIBEXECDIR/xbps-src-docheck.sh $SOURCEPKG $XBPS_CROSS_BUILD || exit 1
[ "$XBPS_TARGET" = "check" ] && exit 0

# Install pkgs into destdir.
$XBPS_LIBEXECDIR/xbps-src-doinstall.sh $SOURCEPKG no $XBPS_CROSS_BUILD || exit 1

for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-doinstall.sh $subpkg yes $XBPS_CROSS_BUILD || exit 1
done
for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-prepkg.sh $subpkg $XBPS_CROSS_BUILD || exit 1
done

for subpkg in ${subpackages} ${sourcepkg}; do
    if [ "$PKGNAME" = "${subpkg}" -a "$XBPS_TARGET" = "install" ]; then
        exit 0
    fi
done

# Clean list of preregistered packages
printf "" > ${XBPS_STATEDIR}/.${sourcepkg}_register_pkg
# If install went ok generate the binpkgs.
for subpkg in ${subpackages} ${sourcepkg}; do
    $XBPS_LIBEXECDIR/xbps-src-dopkg.sh $subpkg "$XBPS_REPOSITORY" "$XBPS_CROSS_BUILD" || exit 1
done

# Registering packages at once per repository. This makes sure that staging is
# triggered for all new packages if any of them introduces inconsistencies.
cut -d: -f 1,2 ${XBPS_STATEDIR}/.${sourcepkg}_register_pkg | sort -u | \
    while IFS=: read -r arch repo; do
        paths=$(grep "^$arch:$repo:" "${XBPS_STATEDIR}/.${sourcepkg}_register_pkg" | \
            cut -d : -f 2,3 | tr ':' '/')
        if [ -z "$XBPS_PRESERVE_PKGS" ] || [ "$XBPS_BUILD_FORCEMODE" ]; then
            force=-f
        fi
        if [ -n "${arch}" ]; then
            msg_normal "Registering new packages to $repo ($arch)\n"
            XBPS_TARGET_ARCH=${arch} $XBPS_RINDEX_CMD \
                ${XBPS_REPO_COMPTYPE:+--compression $XBPS_REPO_COMPTYPE} ${force} -a ${paths}
        else
            msg_normal "Registering new packages to $repo\n"
            if [ -n "$XBPS_CROSS_BUILD" ]; then
                $XBPS_RINDEX_XCMD ${XBPS_REPO_COMPTYPE:+--compression $XBPS_REPO_COMPTYPE} \
					${force} -a ${paths}
            else
                $XBPS_RINDEX_CMD ${XBPS_REPO_COMPTYPE:+--compression $XBPS_REPO_COMPTYPE} \
					${force} -a ${paths}
            fi
        fi
    done

# pkg cleanup
if declare -f do_clean >/dev/null; then
    run_func do_clean
fi

if [ -n "$XBPS_DEPENDENCY" -o -z "$XBPS_KEEP_ALL" ]; then
    remove_pkg_autodeps
    remove_pkg_wrksrc
    remove_pkg $XBPS_CROSS_BUILD
    remove_pkg_statedir
fi

exit 0
