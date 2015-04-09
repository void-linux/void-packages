#! /bin/sh
#
# build.sh

if [ "$1" != x86_64 ]; then
	arch="-a $1"
fi

for pkg in $(cat /tmp/templates); do
	./xbps-src $arch -C pkg "$pkg" || exit 1
done

