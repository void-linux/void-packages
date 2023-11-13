#!/bin/sh

# Flowblade does not support wayland and it crashes
GDK_BACKEND=x11 /usr/bin/flowblade $@
