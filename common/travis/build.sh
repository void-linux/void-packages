#!/bin/sh
#
# build.sh

if [ "$1" != x86_64 ]; then
	arch="-a $1"
fi

for pkg in $(cat /tmp/templates); do
	./xbps-src -H $HOME/hostdir $arch -C pkg "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
