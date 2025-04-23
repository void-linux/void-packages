#!/bin/sh

if [ "$XDG_CURRENT_DESKTOP" != "KDE" ]; then
	export QT_QPA_PLATFORMTHEME=qt5ct
fi
