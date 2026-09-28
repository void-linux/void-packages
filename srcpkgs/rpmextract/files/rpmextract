#!/bin/sh

if [ -z "$1" ]; then
	echo "no package supplied" >&2
	exit 1
elif [ ! -f "$1" ]; then
	echo "'$1': not found" >&2
	exit 1
fi
rpm2cpio "$1" | bsdtar -xf -
