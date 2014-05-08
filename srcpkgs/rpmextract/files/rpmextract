#!/bin/sh
if [ "$1" = "" -o ! -e "$1" ]; then
    echo "no package supplied" 1>&2
   exit 1
fi
rpm2cpio $1 | bsdtar -xf -
