# vim: set ts=4 sw=4 et:

# AppArmor is not enabled in kernel, silently exit
[ ! -d /sys/kernel/security/apparmor ] && return

# Load config
[ -r /etc/default/apparmor ] && . /etc/default/apparmor

# Proceed to load profiles depending on user settings
msg "Loading AppArmor profiles..."

if [ -n "$APPARMOR" ]; then
	if [ "$APPARMOR" != "complain" -a "$APPARMOR" != "enforce" ]; then
		printf '! AppArmor set to %s - ignoring profiles\n' "$APPARMOR"
		return
	fi

	[ "$APPARMOR" = "complain" ] && AACOMPLAIN="-C"

	if [ -d /etc/apparmor.d -a -x /usr/bin/apparmor_parser ]; then
		apparmor_parser -a $AACOMPLAIN $(find /etc/apparmor.d -maxdepth 1 -type f ! -name '*.new-*_*')
	else
		printf '! AppArmor installation problem - ensure you have installed apparmor package\n'
	fi
else
	printf '! AppArmor disabled - ignoring profiles\n'
fi
