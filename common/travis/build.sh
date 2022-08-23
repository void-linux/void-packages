#!/bin/sh
#
# build.sh

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

if [ "$3" = 1 ]; then
	test="-Q"
fi

PKGS=$(/hostrepo/xbps-src sort-dependencies $(cat /tmp/templates))

for pkg in ${PKGS}; do
	/hostrepo/xbps-src -j$(nproc) -s -H "$HOME"/hostdir $arch $test pkg "$pkg"
	ret=$?
	[ $ret -ne 0 ] && exit $ret
done

exit 0
