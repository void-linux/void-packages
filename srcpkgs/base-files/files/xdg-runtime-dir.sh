# Sets and creates XDG_RUNTIME_DIR.

if test -z "${XDG_RUNTIME_DIR}"; then
	export XDG_RUNTIME_DIR=/tmp/${UID:-$(id -u)}-runtime-dir
	if test -w /tmp -a ! test -d "${XDG_RUNTIME_DIR}"; then
		mkdir -p "${XDG_RUNTIME_DIR}" >/dev/null 2>&1
		chmod 0700 "${XDG_RUNTIME_DIR}" >/dev/null 2>&1
	fi
fi
