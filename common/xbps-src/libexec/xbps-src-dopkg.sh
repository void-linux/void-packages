#!//bin/bash
#
# Passed arguments:
#	$1 - pkgname [REQUIRED]
#	$2 - cross target [OPTIONAL]

if [ $# -lt 1 -o $# -gt 2 ]; then
	echo "$(basename $0): invalid number of arguments: pkgname [cross-target]"
	exit 1
fi

PKGNAME="$1"
XBPS_CROSS_BUILD="$2"

. $XBPS_SHUTILSDIR/common.sh

for f in $XBPS_COMMONDIR/helpers/*.sh; do
	source_file "$f"
done

setup_pkg "$PKGNAME" $XBPS_CROSS_BUILD

for f in $XBPS_COMMONDIR/environment/install/*.sh; do
	source_file "$f"
done

XBPS_PKG_DONE="$wrksrc/.xbps_${PKGNAME}_${XBPS_CROSS_BUILD}_pkg_done"

if [ -f $XBPS_PKG_DONE ]; then
	exit 0
fi

#
# Always remove metadata files generated in a previous installation.
#
for f in INSTALL REMOVE files.plist props.plist rdeps shlib-provides shlib-requires; do
	[ -f ${PKGDESTDIR}/${f} ] && rm -f ${PKGDESTDIR}/${f}
done

# If it's a subpkg execute the pkg_install() function.
if [ "$sourcepkg" != "$PKGNAME" ]; then
	# Source all subpkg environment setup snippets.
	for f in ${XBPS_COMMONDIR}/environment/setup-subpkg/*.sh; do
		source_file "$f"
	done
	${PKGNAME}_package
	pkgname=$PKGNAME

	install -d $PKGDESTDIR
	if declare -f pkg_install >/dev/null; then
		export XBPS_PKGDESTDIR=1
		run_func pkg_install
	fi
fi

setup_pkg_depends $pkgname

run_pkg_hooks post-install

touch -f $XBPS_PKG_DONE

exit 0
