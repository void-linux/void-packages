#!/usr/bin/env sh
# Launches Logseq with flags specified in $XDG_CONFIG_HOME/logseq-flags.conf

# Make script fail if `cat` fails for some reason
set -e

# Set default value if variable is unset/null
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

# Attempt to read a config file if it exists
if [ -r "${XDG_CONFIG_HOME}/logseq-flags.conf" ]; then
  LOGSEQ_USER_FLAGS="$(cat "$XDG_CONFIG_HOME/logseq-flags.conf")"
fi

exec /usr/lib/Logseq/Logseq $LOGSEQ_USER_FLAGS "$@"
