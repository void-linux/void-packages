#!/bin/sh

MACHINE=$(uname -m)
if [ "$MACHINE" = "x86_64" ]; then
	export LD_LIBRARY_PATH=/usr/lib32
fi

PULSE_LATENCY_MSEC=30 exec /usr/lib/skype/skype "$@"
