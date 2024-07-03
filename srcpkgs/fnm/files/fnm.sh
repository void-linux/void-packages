#!/bin/sh

if [ "$(xbps-uhelper arch)" = "x86_64-musl" ]; then
    export FNM_NODE_DIST_MIRROR=https://unofficial-builds.nodejs.org/download/release
    export FNM_ARCH=x64-musl
fi
