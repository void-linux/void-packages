The runit service now uses Linux capabilities to run as non-root.
If you edited `wpa_supplicant.conf` files, you must set
	`control_interface_group=_wpas`
there, so that the unprivileged daemon can function properly.
You must also
	`chown -R _wpas:_wpas /run/wpa_supplicant`
before restarting the service with a mounted /run.
Finally, note that due to a bug in wpa_cli, you must run it as
	`(umask 0 && wpa_cli)`
for the supplicant to be able to communicate with it.
