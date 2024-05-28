#!/bin/sh
#
# fetch.sh

PKGS=$(/hostrepo/xbps-src $test sort-dependencies $(cat /tmp/templates))

for pkg in ${PKGS}; do
	/hostrepo/xbps-src -H "$HOME"/hostdir fetch "$pkg"
	[ $? -eq 1 ] && exit 1
done

exit 0
