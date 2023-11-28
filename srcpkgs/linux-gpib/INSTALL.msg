If your GPIB device requires external firmware, you will need to install
firmware files for your device.

Some firmwares are available from https://github.com/fmhess/linux_gpib_firmware
Copy the relevant directories from that repository into /usr/share/usb.
Note: For NI GPIB-USB-B, the directory has to be renamed, from "ni_gpib_usb_b"
to "ni_usb_gpib".

Make sure you have the "fxload" and "udev" packages installed on your computer.
Then, when the device is detected, the udev rules should automatically upload
the firmware to your device and load the driver module.

For more information, see the documentation at /usr/share/doc/linux-gpib
