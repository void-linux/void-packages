#!/bin/sh
#
# show_files.sh

export XBPS_TARGET_ARCH="$2" XBPS_DISTDIR=/hostrepo

while read -r pkg; do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mFiles of $subpkg:\x1b[0m"
		xbps-query --repository=$HOME/hostdir/binpkgs \
				   --repository=$HOME/hostdir/binpkgs/nonfree \
				   -f "$subpkg"
	done
done < /tmp/templates
