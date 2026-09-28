#!/bin/sh
exec 2>&1
[ ! -e /etc/rsyncd.conf ] && exit 1
exec rsync --daemon --no-detach
