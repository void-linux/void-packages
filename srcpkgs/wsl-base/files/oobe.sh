#!/bin/sh

set -eu

ps_env() {
	var="$1"
	val="$(powershell.exe -NoProfile -Command '& {
		[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
		$Env:'"${var}"'}')" 2>/dev/null || true
	echo "${val%%[[:cntrl:]]}"
}

WIN_USER="$(ps_env 'UserName' | tr '[[:upper:]] ' '[[:lower:]]_' | sed 's/[^a-z0-9_-]//g; s/^[^a-z_]//')"
USER_ID=1000
USERNAME=''
DEF_GROUPS='users,wheel'
DEF_SHELL='/bin/bash'
if ! [ -x "$DEF_SHELL" ]; then
	DEF_SHELL='/bin/sh'
fi


if ! getent passwd "$USER_ID" >/dev/null 2>&1; then
	while true; do
		USERNAME=''

		printf 'Linux user account name (default: %s): ' "$WIN_USER"
		read -r USERNAME

		if [ -z "$USERNAME" ]; then
			USERNAME="$WIN_USER"
		fi

		if ! printf '%s' "$USERNAME" | grep -E '^[a-z_][a-z0-9_-]*[$]?$' >/dev/null 2>&1; then
			echo "Invalid username. Must start with a lowercase letter or underscore, and can only contain lowercase letters, numbers,, underscores, and dashes."
			continue
		fi

		if ! /usr/bin/useradd --comment '' --shell "$DEF_SHELL" --groups "$DEF_GROUPS" --uid "$USER_ID" "$USERNAME" >/dev/null 2>&1; then
			echo "Failed to create user '${USERNAME}'. Choose a different name."
			continue
		fi

		if ! /usr/bin/passwd "$USERNAME"; then
			echo "Failed to set password for user '${USERNAME}'. Try again."
			/usr/bin/userdel "$USERNAME"
			continue
		fi

		if getent passwd "$USER_ID" >/dev/null 2>&1; then
			break
		fi
	done

	# allow users in wheel sudo access
	if ! [ -e /etc/sudoers.d/wheel ]; then
		mkdir -p /etc/sudoers.d
		echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/wheel
	fi

	# set user as default
	touch /etc/wsl.conf

	if ! grep -q '^\[user\]' /etc/wsl.conf; then
		printf '\n[user]\ndefault=%s\n' "$USERNAME" >>/etc/wsl.conf
	fi

	if ! sed -n '/^\[user\]/,/^\[/{/^\s*default\s*=/p}' /etc/wsl.conf | grep -q .; then
		sed -i '/^\[user\]/a\default='"${USERNAME}"'\n' /etc/wsl.conf
	fi
fi
