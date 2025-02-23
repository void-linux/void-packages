The runit service now uses Linux capabilities to run as non-root.
If you edited `wpa_supplicant.conf` files, you must set
	`control_interface_group=_wpas`
there, so that the unprivileged daemon can function properly.
