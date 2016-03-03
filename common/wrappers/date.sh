#!/bin/sh

if [ "$SOURCE_DATE_EPOCH" ]; then
	post="--date @$SOURCE_DATE_EPOCH"
fi
exec /usr/bin/date $@ $post
