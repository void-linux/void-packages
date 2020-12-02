#!/bin/sh
#
# fetch-xtools.sh

TAR=tar
command -v bsdtar >/dev/null && TAR=bsdtar
URL="https://github.com/leahneukirchen/xtools/archive/master.tar.gz"
FILE="xtools.tar.gz"

mkdir -p /tmp/bin

/bin/echo -e '\x1b[32mInstalling xtools...\x1b[0m'
if command -v wget >/dev/null; then
	wget -q -O "$FILE" "$URL" || exit 1
else
	xbps-fetch -o "$FILE" "$URL" || exit 1
fi

$TAR xf "$FILE" -C /tmp/bin --strip-components=1 || exit 1
