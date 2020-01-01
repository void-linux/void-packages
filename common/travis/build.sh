#!/bin/bash
#
# build.sh

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

# Make sure `base-chroot` is really up-to-date
/hostrepo/xbps-src -Ntf pkg base-chroot

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
