#!/bin/sh
export CHROME_WRAPPER=/usr/lib/chromium/chromium
export CHROME_DESKTOP=chromium.desktop
CHROME_FLAGS="--enable-gpu-rasterization $CHROME_FLAGS"
case $(xbps-uhelper arch) in
	*-musl) exec /usr/lib/chromium/chromium $CHROME_FLAGS --js-flags="--jitless --wasm_jitless" "$@";;
	*) exec /usr/lib/chromium/chromium $CHROME_FLAGS "$@";;
esac
