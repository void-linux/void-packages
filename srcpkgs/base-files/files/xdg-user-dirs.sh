#!/bin/sh

CFGDIR=$HOME/.config

if [ -f "/usr/bin/xdg-user-dirs-update" ] && [ -f "/usr/bin/xdg-user-dirs-gtk-update" ]; then
	if [ ! -f "$CFGDIR/user-dirs.dirs" ] && [ ! -f "$CFGDIR/user-dirs.locale" ]; then
		xdg-user-dirs-update
		xdg-user-dirs-gtk-update
		echo "XDG user dirs created/updated."
	fi
fi

