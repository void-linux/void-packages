#!/bin/sh
if [ -z "$XDG_VTNR" ]; then
  exec /usr/bin/X -nolisten tcp "$@"
else
  exec /usr/bin/X -nolisten tcp "$@" vt$XDG_VTNR
fi
