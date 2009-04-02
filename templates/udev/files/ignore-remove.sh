#!/bin/sh

if [ -z "$1" ]; then
  exit 1
fi

for f in ${DEVNAME} ${DEVLINKS}; do
  if [ -e "/lib/udev/devices/${f#$1}" ]; then
    exit 0
  fi
done

exit 1
