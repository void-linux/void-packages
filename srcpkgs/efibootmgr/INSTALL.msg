From now on, efibootmgr automatically generates efi boot entries to
directly boot the kernel after every kernel update or installation.

The efi variables need to be accessible in order for this to work, so
add this line to your fstab and reboot or mount manually:
  efivarfs /sys/firmware/efi/efivars efivarfs 0 0
-----------------------------------------------------------------------
Kernel cmd options can be configured in /etc/efibootmgr-options.conf,
but you always have to reconfigure the kernel:

	$ xbps-reconfigure -f linux4.8
	(or any other kernel version)

This is also required after the first installation of this package.
-----------------------------------------------------------------------
The bootorder itself is not changed, so your previous boot loader will
stay enabled until you can edit the order in your firmware interface or
using "efibootmgr -o <hexnum>"
