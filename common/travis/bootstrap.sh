#!/bin/sh
#
# bootstrap.sh

[ "$ACTION" ] && exit 0

./xbps-src -H $HOME/hostdir binary-bootstrap $1
