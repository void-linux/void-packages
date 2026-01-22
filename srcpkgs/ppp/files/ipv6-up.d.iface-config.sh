#!/bin/sh

echo 0 > /proc/sys/net/ipv6/conf/$1/use_tempaddr
echo 2 > /proc/sys/net/ipv6/conf/$1/accept_ra
