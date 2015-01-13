#!/bin/sh

usage() {
	cat >&2 <<EOF
usage: $0 [enable|disable]
EOF
	exit 1;
}

die() {
	echo $@ >&2
	exit 1;
}

LED=/sys/class/leds/led1/brightness
MAXLED=/sys/class/leds/led1/max_brightness



if [ $# -eq 1 ]; then
	[ -z "$1" ] && usage
	behavior=$1
elif [ $# -gt 1 ]; then
	usage;
elif [ -f /etc/default/odroid-led ]; then
	. /etc/default/odroid-led
	behavior=$LED_BOOT_BEHAVIOR
	auto_config=1
else
	exit 1
fi


case "$behavior" in
	enable)
		[ -f $LED -a -f $MAXLED ] || die "LED control file can not be found"
		echo 0 > $LED
		cat $MAXLED > $LED
	;;
	disable)
		[ -f $LED ] || die "LED control file can not be found"
		echo 0 > $LED
	;;
	*)
		[ "$auto_config" ] || usage
		exit 0;
	;;
esac
