#!/bin/sh

uname=$(/usr/bin/uname $@)
rv=$?
uname_m=$(/usr/bin/uname -m)
arch=${XBPS_ARCH%-musl}
# if XBPS_ARCH was reseted by `env -i` use original `/usr/bin/uname -m`
: ${arch:=$uname_m}
echo "$uname" |
	sed "s/\(^\| \)$(/usr/bin/uname -n)\($\| \)/\1void\2/" |
	sed "s/$uname_m/$arch/"

exit $rv
