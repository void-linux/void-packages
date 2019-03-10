#!/bin/sh
#
# show_files.sh

[ "$XLINT" ] && exit 0 

export XBPS_TARGET_ARCH="$2"

for pkg in $(cat /tmp/templates); do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mFiles of $subpkg:\x1b[0m"
		xbps-query --repository=$HOME/hostdir/binpkgs -f "$subpkg"
	done
done

