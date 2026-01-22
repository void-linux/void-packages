# This hook fixes permissions in common places

change_file_perms() {
	local dir="${PKGDESTDIR}${1}"
	# permission mask for matching the files
	local permmask="$2"
	# permissions which will be set on matched files
	local perms="$3"
	if [ -d "$dir" ]; then
		find "$dir" -type f -perm "/$permmask" -exec chmod -v "$perms" {} +
	fi
}

hook() {
	if [ -z "$nocheckperms" ]; then
		# check that no files have permission write for other users
		find "$PKGDESTDIR" -type f -perm -0002 | while read -r file; do
			msg_error "$pkgver: file ${file#$PKGDESTDIR} has write permission for other users\n"
		done
	fi

	if [ -z "$nofixperms" ]; then
		change_file_perms "/usr/share/man" 133 644
		change_file_perms "/etc/apparmor.d" 111 644
		change_file_perms "/usr/share/applications" 133 644
		change_file_perms "/usr/share/help" 133 644
		change_file_perms "/usr/share/icons" 133 644
		change_file_perms "/usr/share/locale" 133 644
		change_file_perms "/usr/share/metainfo" 133 644
		change_file_perms "/usr/share/appdata" 133 644
		change_file_perms "/usr/include" 133 644
		change_file_perms "/usr/share/bash-completion/completions" 133 644
		change_file_perms "/usr/share/fish/vendor_completions.d" 133 644
		change_file_perms "/usr/share/zsh/site-functions" 133 644
	fi
}
