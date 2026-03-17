The dracut-uefi install and remove scripts are now controlled by the
initramfs alternative group. To use dracut-uefi to generate unified
kernel image initramfses, run:

	xbps-alternatives -s dracut-uefi

Then (re)generate the UKIs with:

	xbps-reconfigure -f linux6.Y
