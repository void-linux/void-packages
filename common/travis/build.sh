#!/bin/sh
#
# build.sh

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

# Tell xbps-src what is our arch, this is done when doing
# binary-bootstrap, but we need to do it every time since
# our masterdir is ethereal.
/bin/echo -e '\x1b[32mWriting bootstrap arch into .xbps_chroot_init of masterdir\x1b[0m'
echo "$1" > /hostrepo/masterdir/.xbps_chroot_init

PKGS=$(/hostrepo/xbps-src sort-dependencies $(cat /tmp/templates))

for pkg in ${PKGS}; do
	/hostrepo/xbps-src -H "$HOME"/hostdir $arch pkg "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
