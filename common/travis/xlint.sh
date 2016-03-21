#!/bin/sh
#
# xlint.sh

[ "$ACTION" = "xlint" ] || exit 0 

awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates | xargs xlint
