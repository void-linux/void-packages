#!/bin/sh
#
# fetch-xtools.sh

mkdir -p /tmp/bin

/bin/echo -e '\x1b[32mInstalling xtools...\x1b[0m'

if command -v bsdtar >/dev/null; then
	TAR=bsdtar
	_tar_wildcard=
elif command -v tar >/dev/null; then
	TAR=tar
	_tar_wildcard=--wildcards
else
	echo "tar and bsdtar: not found"
	exit 1
fi

_link=https://github.com/leahneukirchen/xtools/archive/master.tar.gz
if command -v xbps-fetch >/dev/null; then
	xbps-fetch $_link >/dev/null 2>&1
	cat ${_link##*/}
else
	wget -q -O - $_link
fi |
gunzip |
$TAR xf - -C /tmp/bin --strip-components=1 ${_tar_wildcard} "xtools-master/x*" ||
exit 1
rm -f ${_link##*/}
