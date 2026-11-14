The `/etc/default/apparmor` configuration file was removed. The system will now
boot in `enforce` mode by default if apparmor is enabled.

To boot in complain mode, add `apparmor.mode=complain` to the kernel command
line, or change the mode at runtime:

	# echo -n complain > /sys/module/apparmor/parameters/mode
