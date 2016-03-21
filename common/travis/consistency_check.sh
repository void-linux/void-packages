#!/bin/sh
#
# consistency_check.sh

[ "$ACTION" = "consistency-check" ] || exit 0 

./xbps-src consistency-check
