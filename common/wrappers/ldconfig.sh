#!/bin/sh

if [ "$1" = "-p" ]; then
	exec /usr/bin/ldconfig "$@"
fi

echo "ldconfig-wrapper: ignoring arguments: $@"
exit 0
