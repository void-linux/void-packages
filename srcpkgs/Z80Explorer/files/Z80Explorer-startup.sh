#!/bin/sh
#
# Ensure there is an initial configuration file
#
CFG="Baltazar Studios, LLC/Z80Explorer.conf" 
if [ ! -f "$HOME/.config/$CFG" ]; then
	mkdir -p "$HOME/.config/Baltazar Studios, LLC"
	cat >"$HOME/.config/$CFG" <<-EOF
	[General]
	ResourceDir=/usr/share/Z80Explorer
	EOF
fi
/usr/libexec/Z80Explorer/Z80Explorer
