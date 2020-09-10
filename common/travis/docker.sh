#!/bin/sh
#
# docker.sh

[ "$XLINT" ] && exit 0

DOCKER_NAME=${DOCKER_NAME:-void}

/bin/echo -e "\x1b[32mPulling docker image $DOCKER_BASE-$BOOTSTRAP:$TAG...\x1b[0m"
docker pull $DOCKER_BASE-$BOOTSTRAP:$TAG
docker run -d \
	   --name $DOCKER_NAME \
	   -v "$(pwd)":/hostrepo \
	   -v /tmp:/tmp \
	   -e XLINT="$XLINT" \
	   -e PATH="$PATH" \
	   $DOCKER_BASE-$BOOTSTRAP:$TAG \
	   /bin/sh -c 'sleep inf'
