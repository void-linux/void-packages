# vim: set ts=4 sw=4 et:

# AppArmor is not enabled in kernel, silently exit
[ ! -d /sys/module/apparmor ] && return
[ ! -d /sys/kernel/security/apparmor ] && return

# Proceed to load profiles depending on user settings
msg "Loading AppArmor profiles..."

if [ -d /etc/apparmor.d -a -x /usr/bin/apparmor_parser ]; then
	apparmor_parser -a -- /etc/apparmor.d
else
	printf '! AppArmor installation problem - ensure you have installed apparmor package\n'
fi
