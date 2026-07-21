#!/bin/bash

set -e

TRAVIS_MIRROR=repo-ci.voidlinux.org

for _i in etc/xbps.d/repos-remote*.conf ; do
    /bin/echo -e "\x1b[32mUpdating $_i...\x1b[0m"
    sed -i "s:repo-default\.voidlinux\.org:$TRAVIS_MIRROR:g" $_i
done
