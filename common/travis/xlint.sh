#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0

EXITCODE=0
read base tip < /tmp/revisions

common/scripts/lint-commits $base $tip || EXITCODE=$?

for t in $(awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates); do
	/bin/echo -e "\x1b[32mLinting $t...\x1b[0m"
	if grep -q "^$t\$" /tmp/new-templates; then
		# only fatal if xlint fails for new templates
		xlint "$t" > /tmp/xlint_out || EXITCODE=$?
	else
		xlint "$t" > /tmp/xlint_out || true
	fi
	common/scripts/lint-version-change "srcpkgs/$t/template" $base $tip > /tmp/vlint_out || EXITCODE=$?
	awk -f common/scripts/lint2annotations.awk /tmp/xlint_out /tmp/vlint_out
done
exit $EXITCODE
