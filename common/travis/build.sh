#!/bin/bash
#
# build.sh

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

# Make sure `base-chroot` is really up-to-date
/hostrepo/xbps-src -f pkg base-chroot || exit 1
xbps-install --repository=/host/binpkgs -yif base-chroot || exit 1
# remove autodeps
xbps-remove -yo || exit 1

PKGS=$(/hostrepo/xbps-src sort-dependencies $(cat /tmp/templates))

NPROCS=1
if [ -r /proc/cpuinfo ]; then
        NPROCS=$(grep ^proc /proc/cpuinfo|wc -l)
fi

for pkg in ${PKGS}; do
	/hostrepo/xbps-src -j$NPROCS -H "$HOME"/hostdir $arch pkg "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
