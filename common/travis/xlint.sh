#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0 

awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates | while read -r t; do
	/bin/echo -e "\x1b[32mLinting $t...\x1b[0m"
	xlint "$t"
done
