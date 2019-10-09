#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0 

EXITCODE=0
for t in $(awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates); do
	/bin/echo -e "\x1b[32mLinting $t...\x1b[0m"
	xlint "$t" || EXITCODE=$?
done
exit $EXITCODE
