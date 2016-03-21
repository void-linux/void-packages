#!/bin/sh
#
# show_files.sh

[ "$ACTION" ] && exit 0 

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

for pkg in $(cat /tmp/templates); do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mFiles of $subpkg:\x1b[0m"
		./xbps-src -H $HOME/hostdir $arch show-files "$subpkg"
	done
done

