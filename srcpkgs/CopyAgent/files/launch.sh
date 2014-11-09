#!/bin/sh

export LD_LIBRARY_PATH=/opt/copy
exec /opt/copy/${0##*/} $@
