#!/bin/sh
#
# show_files.sh

export XBPS_TARGET_ARCH="$2" XBPS_DISTDIR=/hostrepo

for pkg in $(cat /tmp/templates); do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mFiles of $subpkg:\x1b[0m"
		xbps-query --repository=$HOME/hostdir/binpkgs -f "$subpkg"
	done
done

