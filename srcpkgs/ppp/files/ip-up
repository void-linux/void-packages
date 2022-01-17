#!/bin/sh
#
# This script is run by pppd when there's a successful ppp connection.
#

# Execute all scripts in /etc/ppp/ip-up.d/
for ipup in /etc/ppp/ip-up.d/*.sh; do
  if [ -x $ipup ]; then
    # Parameters: interface-name tty-device speed local-IP-address remote-IP-address ipparam
    $ipup "$@"
  fi
done
