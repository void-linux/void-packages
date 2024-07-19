#!/bin/sh
#
# This script is run by pppd after the connection has ended.
#

# Execute all scripts in /etc/ppp/ip-up.d/
for ipdown in /etc/ppp/ip-down.d/*.sh; do
  if [ -x $ipdown ]; then
    # Parameters: interface-name tty-device speed local-IP-address remote-IP-address ipparam
    $ipdown "$@"
  fi
done
