#!/bin/sh
#
# xpkgdiff.sh

export XBPS_TARGET_ARCH="$2" XBPS_DISTDIR=/hostrepo XBPS_HOSTDIR="$HOME/hostdir"
export DIFF='diff --unified=0 --report-identical-files --suppress-common-lines
 --color=always --label REPO --label BUILT'

while read -r pkg; do
	for subpkg in $(xsubpkg $pkg); do
		if xbps-query --repository=$HOME/hostdir/binpkgs \
					  --repository=$HOME/hostdir/binpkgs/nonfree \
					  -i "$subpkg" >&/dev/null; then
			/bin/echo -e "\x1b[34mFile Diff of $subpkg:\x1b[0m"
			xpkgdiff -f $subpkg
			/bin/echo -e "\x1b[34mMetadata Diff of $subpkg:\x1b[0m"
			xpkgdiff -S $subpkg
			/bin/echo -e "\x1b[34mDependency Diff of $subpkg:\x1b[0m"
			xpkgdiff -x $subpkg
		else
			/bin/echo -e "\x1b[33m$subpkg wasn't found\x1b[0m"
		fi
	done
done < /tmp/templates
