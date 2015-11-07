#!/bin/sh
#
# Startup script for anura using the frogatto module
#
cd /usr/share/anura
exec /usr/lib/anura/anura --config-path=~/.frogatto $*
