#!/bin/bash
#
# build.sh

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

if [ "$3" = 1 ]; then
	test="-Q"
fi

PKGS=$(./xbps-src $test sort-dependencies $(cat /tmp/templates))

for pkg in ${PKGS}; do
	./xbps-src -j$(nproc) -s $arch $test pkg "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
