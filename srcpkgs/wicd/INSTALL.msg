Please note that wicd does not require to have dhcpcd and/or
wpa_supplicant services running at boot. If you are using them at
boot, please disable them before using wicd. You can do that with:

	# rm -f /var/service/{dhcpcd,wpa_supplicant}

ATTENTION: to make wicd work for your user, it must be a member
of the 'network' group. You may need 'kdesu' for privilege 
elevation.
