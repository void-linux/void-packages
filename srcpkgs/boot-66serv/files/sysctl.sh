#!/bin/sh

# Copy of the 08-syctl.sh script of the void-runit project,
# that is in the public domain.
# Latest version of the upstream script is in:
# https://github.com/void-linux/void-runit/blob/master/core-services/08-sysctl.sh
# Licence information is available in the README.md:
# https://github.com/void-linux/void-runit#readme

if [ -x /sbin/sysctl -o -x /bin/sysctl ]; then
	mkdir -p /run/vsysctl.d
    for i in /run/sysctl.d/*.conf \
        /etc/sysctl.d/*.conf \
        /usr/local/lib/sysctl.d/*.conf \
        /usr/lib/sysctl.d/*.conf; do

        if [ -e "$i" ] && [ ! -e "/run/vsysctl.d/${i##*/}" ]; then
            ln -s "$i" "/run/vsysctl.d/${i##*/}"
        fi
    done
    for i in /run/vsysctl.d/*.conf; do
        sysctl -p "$i"
    done
    rm -rf -- /run/vsysctl.d
    sysctl -p /etc/sysctl.conf
fi
