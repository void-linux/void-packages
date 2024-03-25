#!/bin/sh
#
# check-install.sh

export XBPS_TARGET_ARCH="$2" XBPS_DISTDIR=/hostrepo

if [ "$1" != "$XBPS_TARGET_ARCH" ]; then
	triplet="$(/hostrepo/xbps-src -a "$XBPS_TARGET_ARCH" show-var XBPS_CROSS_TRIPLET)"
	CONFDIR="-C /usr/$triplet/etc/xbps.d"
else
	CONFDIR="-C /etc/xbps.d"
fi

mkdir /check-install

mkdir -p /check-install/var/db/xbps/keys
cp /var/db/xbps/keys/* /check-install/var/db/xbps/keys/

ADDREPO="--repository=$HOME/hostdir/binpkgs/bootstrap
 --repository=$HOME/hostdir/binpkgs
 --repository=$HOME/hostdir/binpkgs/nonfree"
ROOTDIR="-r /check-install"

xbps-install $ROOTDIR $ADDREPO $CONFDIR -S

while read -r pkg; do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mTrying to install dependants of $subpkg:\x1b[0m"
		for dep in $(xbps-query $ADDREPO -RX "$subpkg"); do
			xbps-install \
				$ROOTDIR $ADDREPO $CONFDIR \
				-ny \
				"$subpkg" "$(xbps-uhelper getpkgname "$dep")"
			ret="$?"
			if [ "$ret" -eq 8 ] || [ "$ret" -eq 11 ]; then
				/bin/echo -e "\x1b[31mFailed to install '$subpkg' and '$dep'\x1b[0m"
				exit 1
			fi
		done
	done
done < /tmp/templates
