# Check for interactive bash
[ -z "$BASH_VERSION" -o -z "$PS1" ] && return

# Bash login shells only run /etc/profile
# Bash non-login shells run only /etc/bash/bashrc
# We want to source /etc/bash/bashrc in any case
[ -f /etc/bash/bashrc ] && . /etc/bash/bashrc
