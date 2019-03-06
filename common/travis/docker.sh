#!/bin/sh
#
# docker.sh

[ "$XLINT" ] && exit 0

/bin/echo -e "\x1b[32mPulling docker image for $BOOTSTRAP from $TAG...\x1b[0m"
docker pull voidlinux/masterdir-$BOOTSTRAP:$TAG
docker run -d \
	   --name void \
	   -v "$(pwd)":/hostrepo \
	   -v /tmp:/tmp \
	   -e XLINT="$XLINT" \
	   -e PATH="$PATH" \
	   voidlinux/masterdir-$BOOTSTRAP:$TAG \
	   /bin/sh -c 'sleep inf'
