#!/bin/sh

uname=$(/usr/bin/uname $@)
rv=$?
echo "$uname" | sed "s/\(^\| \)$(/usr/bin/uname -n)\($\| \)/\1void\2/"
exit $rv
