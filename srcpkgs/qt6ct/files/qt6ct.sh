#!/usr/bin/env sh

if [ "$XDG_CURRENT_DESKTOP" != "KDE" ]; then
	export QT_QPA_PLATFORMTHEME=qt5ct
fi
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
	export QT_QPA_PLATFORM=wayland
fi
