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
		for profile in /etc/apparmor.d/*; do
		case "$profile" in
			*.new-*_*) continue ;;
		esac
		if [ -f "$profile" ]; then
			printf '* Load profile %s: %s\n' "($APPARMOR)" "$profile"
			apparmor_parser -a $AACOMPLAIN "$profile"
		fi
		done
	else
		printf '! AppArmor installation problem - ensure you have installed apparmor package\n'
	fi
else
	printf '! AppArmor disabled - ignoring profiles\n'
fi
