The runit service now uses Linux capabilities to run as non-root.
If you edited `wpa_supplicant.conf` file, you must set
	`control_interface_group=_wpas`
there, so that the unprivileged daemon can function properly.

Since main conf file is now 644, you must move all secrets to either an
external file (using the ext file backend) or an additional .conf file
(for wpa3), passed via the -I option to the daemon.

You must also
	`chown -R _wpas:_wpas /run/wpa_supplicant`
before restarting the service with a mounted /run.

Finally, due to a bug in wpa_cli, you must run it as
	`(umask 0 && wpa_cli)`
for the supplicant to be able to communicate with it.
