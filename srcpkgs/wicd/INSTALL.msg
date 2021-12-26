Please note that wicd requires that no other network management daemons (like
dhcpcd or wpa_supplicant) are running. If you are using them, please disable
them before using wicd. You can do that with:

	# rm /var/service/<service>

NOTE: You may need a graphical sudo program like kdesu for privilege elevation.
