# a version can be pinned by adding zigX.Y to hostmakedepends
if [[ " ${hostmakedepends} " != *[[:space:]]zig[0-9]* ]]; then
	hostmakedepends+=" zig"
fi
