#!/bin/sh
#
# show_files.sh

export XBPS_TARGET_ARCH="$2" XBPS_DISTDIR=/hostrepo

while read -r pkg; do
	for subpkg in $(xsubpkg $pkg); do
		/bin/echo -e "\x1b[32mFiles of $subpkg:\x1b[0m"
		xbps-query --repository=$HOME/hostdir/binpkgs/bootstrap \
				   --repository=$HOME/hostdir/binpkgs \
				   --repository=$HOME/hostdir/binpkgs/nonfree \
				   -i -f "$subpkg" ||
					/bin/echo -e "\x1b[33m    $subpkg wasn't found\x1b[0m"
	done
done < /tmp/templates
