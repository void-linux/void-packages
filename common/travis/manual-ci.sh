#!/bin/sh

echo "Checking links"
RUST_LOG=linkcheck=debug mdbook build manual
LINKCHECK=$?

# Generate exit value
if [ ! $LINKCHECK -eq 0 ] ; then
    exit 2
fi
