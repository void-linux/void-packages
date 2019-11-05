#!/bin/sh
#
# fetch-xtools.sh

mkdir -p /tmp/bin

/bin/echo -e '\x1b[32mInstalling xtools...\x1b[0m'
wget -q -O - https://github.com/chneukirchen/xtools/archive/master.tar.gz | \
	gunzip | tar x -C /tmp/bin --wildcards "xtools-master/x*" \
	--strip-components=1 || exit 1
