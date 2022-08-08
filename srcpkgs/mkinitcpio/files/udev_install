#!/bin/bash

build() {
    add_file "/etc/udev/udev.conf"
    add_binary /usr/bin/udevd
    add_binary /usr/bin/udevadm

    for rule in 50-udev-default.rules 60-persistent-storage.rules 64-btrfs.rules 80-drivers.rules; do
        add_file "/usr/lib/udev/rules.d/$rule"
    done

    for tool in ata_id scsi_id; do
        add_file "/usr/lib/udev/$tool"
    done

    add_runscript
}

help() {
    cat <<HELPEOF
This hook will use udev to create your root device node and detect the needed
modules for your root device. It is also required for firmware loading in
initramfs. It is recommended to use this hook.
HELPEOF
}

# vim: set ft=sh ts=4 sw=4 et:
