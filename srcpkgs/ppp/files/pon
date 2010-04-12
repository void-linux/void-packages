#!/bin/sh

case "$1" in
  -*) echo "
Usage: pon [provider] [arguments]

If you specify one argument, a PPP connection will be started using
settings from the appropriate file in the /etc/ppp/peers/ directory, and
any additional arguments supplied will be passed as extra arguments to
pppd.
"
      exit 0
      ;;
esac

if [ -z "$1" -a ! -f /etc/ppp/peers/provider ]; then
  echo "
Please configure /etc/ppp/peers/provider or use a command line argument to
use another file in /etc/ppp/peers/ directory.
"
  exit 1
fi

if [ "$1" -a ! -f "/etc/ppp/peers/$1" ]; then
  echo "
The file /etc/ppp/peers/$1 does not exist.
"
  exit 1
fi

exec /usr/sbin/pppd call ${@:-provider}

