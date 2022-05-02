#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0 

EXITCODE=0
read base tip < /tmp/revisions

common/scripts/lint-commits $base $tip || EXITCODE=$?

for t in $(awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates); do
	/bin/echo -e "\x1b[32mLinting $t...\x1b[0m"
	xlint "$t" > /tmp/lint_out || EXITCODE=$?
#	if [ "$?" -ne 0 ]; then
		awk '{
			split($0, a, ": ")
			split(a[1], b, ":")
			msg = substr($0, index($0, ": ") + 2)
			if (b[2]) {
				line = ",line=" b[2]
			}
			print $0
			printf "::error title=xlint,file=%s%s::%s\n", b[1], line, msg
		}' /tmp/lint_out
#	fi
	common/scripts/lint-version-change "$t" $base $tip || EXITCODE=$?
done
exit $EXITCODE
