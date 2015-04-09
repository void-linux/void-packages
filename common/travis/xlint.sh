#! /bin/sh
#
# xlint.sh

awk '{ print "srcpkgs/" $0 "/template" }' /tmp/templates | xargs xlint
