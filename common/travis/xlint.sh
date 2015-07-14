#!/bin/sh
#
# xlint.sh

[ "$XLINT" ] || exit 0 

awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates | xargs xlint
