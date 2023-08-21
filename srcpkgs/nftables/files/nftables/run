#!/bin/sh
exec 2>&1
[ ! -r /etc/nftables.conf ] && exit 0
nft -f /etc/nftables.conf
exec chpst -b nftables pause
