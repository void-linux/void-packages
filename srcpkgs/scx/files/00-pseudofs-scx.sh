#!/bin/sh
mountpoint -q /sys/kernel/debug || mount -o nosuid,noexec,nodev -t debugfs debugfs /sys/kernel/debug
