#!/bin/sh
export CHROME_WRAPPER=/usr/lib/chromium/chromium
export CHROME_DESKTOP=chromium.desktop
CHROME_FLAGS="--enable-gpu-rasterization"
exec /usr/lib/chromium/chromium $CHROME_FLAGS "$@"
