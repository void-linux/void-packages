#!/bin/bash

OBSIDIAN_USER_FLAGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/obsidian/user-flags.conf"

# Allow users to override command-line options
if [[ -f "${OBSIDIAN_USER_FLAGS_FILE}" ]]; then
   OBSIDIAN_USER_FLAGS=$(grep -v '^#' "$OBSIDIAN_USER_FLAGS_FILE")
fi

# Launch
exec electron35 /usr/lib/obsidian/app.asar $OBSIDIAN_USER_FLAGS "$@"
