#!/bin/sh

TRAVIS_PROTO=http
TRAVIS_MIRROR=198.204.250.219

for _i in etc/repos-remote.conf etc/defaults.conf etc/repos-remote-x86_64.conf ; do
    printf '\x1b[32mUpdating %s...\x1b[0m\n' $_i
    # First fix the proto, ideally we'd serve everything with HTTPS,
    # but key management and rotation is a pain, and things are signed
    # so we can afford to be a little lazy at times.
    sed -i "s:https:$TRAVIS_PROTO:g" $_i

    # Now set the mirro
    sed -i "s:repo\.voidlinux\.eu:$TRAVIS_MIRROR:g" $_i
done
