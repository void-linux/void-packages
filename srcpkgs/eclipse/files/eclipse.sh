#!/bin/sh
export ECLIPSE_HOME=/usr/lib/eclipse
export GDK_NATIVE_WINDOWS=true
exec ${ECLIPSE_HOME}/eclipse "$@"
