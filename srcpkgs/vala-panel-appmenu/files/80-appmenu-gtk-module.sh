#!/bin/sh
# Loads appmenu-gtk-module via GTK_MODULES at X session start, so GTK2/3
# apps export their menu over DBusMenu instead of rendering it in-window.
if [ -n "$GTK_MODULES" ]; then
	GTK_MODULES="${GTK_MODULES}:appmenu-gtk-module"
else
	GTK_MODULES="appmenu-gtk-module"
fi
if [ -z "$UBUNTU_MENUPROXY" ]; then
	UBUNTU_MENUPROXY=1
fi
export GTK_MODULES
export UBUNTU_MENUPROXY
