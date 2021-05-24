#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0 

EXITCODE=0
read base tip < /tmp/revisions
for t in $(awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates); do
	/bin/echo -e "\x1b[32mLinting $t...\x1b[0m"
	xlint "$t" || EXITCODE=$?
	common/scripts/lint-version-change "$t" $base $tip || EXITCODE=$?
done
exit $EXITCODE
