#!/bin/sh
# runs update-check on all changed templates, then errors only if there was an
# issue with the update-check. does not error if further updates are available,
# as there may be a good reason not to update to those versions

set -e

export XBPS_UPDATE_CHECK_VERBOSE=yes
err=0

while read -r pkg; do
	/bin/echo -e "\x1b[34mVerifying update-check of $pkg:\x1b[0m"
	./xbps-src update-check "$pkg" 2>&1 > /tmp/update-check.log || err=1
	cat /tmp/update-check.log
	if grep -q 'NO VERSION' /tmp/update-check.log; then
		echo "::warning file=srcpkgs/$pkg/template,line=1,title=update-check failed::verify and fix update-check for $pkg"
	fi
done < /tmp/templates

exit $err
