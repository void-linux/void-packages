#!/bin/sh

TRAVIS_MIRROR=repo-us.voidlinux.org

for _i in etc/xbps.d/repos-remote*.conf ; do
    /bin/echo -e "\x1b[32mUpdating $_i...\x1b[0m"
    sed -i "s:repo\.voidlinux\.org:$TRAVIS_MIRROR:g" $_i
done
