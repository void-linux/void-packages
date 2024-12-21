The runit service now uses Linux capabilities to run as non-root.
If the user edited `wpa_supplicant.conf` files, they must set
	`control_interface_group=_wpas`
there, so that the unprivileged daemon can function properly.
