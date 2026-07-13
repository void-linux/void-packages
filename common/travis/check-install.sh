#!/bin/bash
#
# check-install.sh

set -e

HOST_ARCH="$1"
export XBPS_TARGET_ARCH="$2"

if [ "$HOST_ARCH" != "$XBPS_TARGET_ARCH" ]; then
	triplet="$(./xbps-src -a "$XBPS_TARGET_ARCH" show-var XBPS_CROSS_TRIPLET)"
	CONFDIR="-C $PWD/masterdir-$HOST_ARCH/usr/$triplet/etc/xbps.d"
else
	CONFDIR="-C $PWD/masterdir-$HOST_ARCH/etc/xbps.d"
fi

if ! [ -d /check-install ]; then
	/bin/echo -e "\x1b[31m/check-install does not exist\x1b[0m"
	exit 1
fi

mkdir -p /check-install/var/db/xbps/keys
cp /var/db/xbps/keys/* /check-install/var/db/xbps/keys/

ADDREPO="--repository=hostdir/binpkgs/bootstrap
 --repository=hostdir/binpkgs
 --repository=hostdir/binpkgs/nonfree"
ROOTDIR="-r /check-install"

# HACK: remove remote bootstrap repo from consideration
# if the libc package is virtual (like musl1.1), xbps
# can choose the one provided by cross-vpkg-dummy instead
# of the actual package
# this is fine to do here because it runs last in CI
for f in "${CONFDIR#-C }"/*remote*.conf; do
	[ -e "$f" ] || break
	sed -i -e '/bootstrap/d' "$f"
done

# if this fails, there were no packages built for this arch and thus no repodatas
xbps-install $ROOTDIR $ADDREPO $CONFDIR -S || exit 0

failed=()
while read -r pkg; do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mTrying to install dependents of $subpkg:\x1b[0m"
		for dep in $(xbps-query $ADDREPO -RX "$subpkg"); do
			ret=0
			xbps-install \
				$ROOTDIR $ADDREPO $CONFDIR \
				-ny \
				"$subpkg" "$(xbps-uhelper getpkgname "$dep")" \
				|| ret="$?"
			if [ "$ret" -ne 0 ]; then
				/bin/echo -e "\x1b[31mFailed to install '$subpkg' and '$dep'\x1b[0m"
				failed+=("Failed to install '$subpkg' and '$dep'")
			fi
		done
	done
done < /tmp/templates
for msg in "${failed[@]}"; do
	/bin/echo -e "\x1b[31m$msg\x1b[0m"
done
exit ${#failed[@]}
