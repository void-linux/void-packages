#!/bin/sh

TRAVIS_PROTO=http
TRAVIS_MIRROR=repo-us.voidlinux.org

for _i in etc/xbps.d/repos-remote*.conf ; do
    /bin/echo -e "\x1b[32mUpdating $_i...\x1b[0m"
    # First fix the proto, ideally we'd serve everything with HTTPS,
    # but key management and rotation is a pain, and things are signed
    # so we can afford to be a little lazy at times.
    sed -i "s:https:$TRAVIS_PROTO:g" $_i

    # Now set the mirror
    sed -i "s:alpha\.de\.repo\.voidlinux\.org:$TRAVIS_MIRROR:g" $_i
    sed -i "s:repo-default\.voidlinux\.org:$TRAVIS_MIRROR:g" $_i
done
