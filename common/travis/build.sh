#!/bin/sh
#
# build.sh

[ "$ACTION" ] && exit 0 

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

PKGS=$(./xbps-src sort-dependencies $(cat /tmp/templates))

for pkg in ${PKGS}; do
	./xbps-src -H $HOME/hostdir $arch -C pkg "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
