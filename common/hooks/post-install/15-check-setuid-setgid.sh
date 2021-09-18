dofind() {
	error=
	for setidfile in $(find "$PKGDESTDIR" -type f -perm -"$1"); do
		matched=
		for allowed_file in ${!2}; do
			if [ "$PKGDESTDIR$allowed_file" = "$setidfile" ]; then
				matched=y
				break
			fi
		done
		if [ -n "$matched" ]; then
			echo "$2 file: ${setidfile#$PKGDESTDIR}"
		else
			msg_red "not allowed $2 file: ${setidfile#$PKGDESTDIR}\n"
			error=y
		fi
	done
	if [ -n "$error" ]; then
		msg_error "$2 files not explicitly allowed, please list them in \$$2\n"
	fi
}

hook() {
	dofind 4000 setuid
	dofind 2000 setgid
}
