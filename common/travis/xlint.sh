#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0

mkdir -p /usr/share/spdx/
cp common/travis/license.lst /usr/share/spdx/

awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates | while read -r t; do
	/bin/echo -e "\x1b[32mLinting $t...\x1b[0m"
	xlint "$t"
done
