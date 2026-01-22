The upstream mkinitcpio-encryptssh package has been ABANDONED in favor of the
combination of mkinitcpio-netconf, mkinitcpio-dropbear and mkinitcpio-utils
(which now provides the `encryptssh` hook). The `dropbear` hook now provided by
mkinitcpio-dropbear will not configure networking. Users of the older
`encryptssh` hook should add the `netconf` hook to the HOOKS array in
mkinitcpio.conf, BEFORE the `dropbear` hook, to preserve existing behavior.
