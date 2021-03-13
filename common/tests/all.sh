#!/usr/bin/env bash

if ! command -v bats > /dev/null; then
	echo Missing 'bats' command
	exit 1
fi

for i in "$(dirname "$0")"/*.bats; do
	echo $i
	bats "$i"
done
