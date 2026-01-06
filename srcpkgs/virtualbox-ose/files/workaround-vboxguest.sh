# Fix for wrong older vboxguest dkms module version being loaded by default, coming from initramfs,
# preventing load of the proper version of the vboxguest dkms module coming with this package,
# and breaking vbosf at boot time (and therefore file sharing with the host) - see issue #58300.

modprobe -r vboxguest
