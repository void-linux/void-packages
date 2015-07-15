#!/bin/sh
#
# build.sh

[ "$XLINT" ] && exit 0 

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

for pkg in $(cat /tmp/templates); do
	./xbps-src -H $HOME/hostdir $arch -C pkg "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
