#!/bin/bash
#
# build.sh

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

# Tell xbps-src what is our arch, this is done when doing
# binary-bootstrap, but we need to do it every time since
# our masterdir is ethereal.
# /bin/echo -e '\x1b[32mWriting bootstrap arch into .xbps_chroot_init of masterdir\x1b[0m'
# echo "$1" > /hostrepo/masterdir/.xbps_chroot_init

/bin/echo -e '\x1b[32mPreparing chroot with chroot_prepare()\x1b[0m'
source hostrepo/common/xbps-src/shutils/chroot.sh || {
	echo "Failed to source chroot.sh for chroot_prepare()" >&2 ;
	exit 1
}

XBPS_SRCPKGDIR=/hostrepo/srcpkgs XBPS_MASTERDIR=/ chroot_prepare $1 || {
	echo "Failed to prepare chroot!" >&2 ;
	exit 1
}

# Two times due to updating xbps itself
/hostrepo/xbps-src -H "$HOME"/hostdir bootstrap-update
/hostrepo/xbps-src -H "$HOME"/hostdir bootstrap-update

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
