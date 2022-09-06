#!/bin/sh

ret=0

while test $# != 0; do
	case "$1" in
	-*)	;;
	*) command -v "$1" || ret=1 ;;
	esac
	shift
done

exit "$ret"
