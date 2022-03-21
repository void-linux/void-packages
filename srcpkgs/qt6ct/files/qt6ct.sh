#!/usr/bin/env sh

export QT_QPA_PLATFORMTHEME=qt5ct
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
	export QT_QPA_PLATFORM=wayland
fi
