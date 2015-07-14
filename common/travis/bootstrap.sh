#!/bin/sh
#
# bootstrap.sh

[ "$XLINT" ] && exit 0

./xbps-src -H $HOME/hostdir binary-bootstrap $1
