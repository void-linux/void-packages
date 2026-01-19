#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

set -x

rm -rf /etc/rancher/rke2
rm -rf /etc/rancher/node
rm -rf /var/lib/rancher/rke2
rm -rf /var/log/socklog/rke2-server
rm -rf /var/log/socklog/rke2-agent
