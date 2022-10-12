udev rules for uinput has been installed,
to access /dev/uinput, add yourself to group input:

    $ sudo usermod -a -G input $USER

and then re-login to make it effective.
