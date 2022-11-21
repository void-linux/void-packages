# vim: ft=bash
# This hooks will warn if nothing linked with Python
# but python3-devel has been installed

hook() {
	local _file _elf _rx
	local _have_elf=
	# Skip during bootstrapping
	if [ ! "$CHROOT_READY" ]; then return 0; fi
	if [ "$noverifyrdeps" ]; then return 0; fi
	if [ "$noverifypython" ]; then return 0; fi
	# We may want to $XBPS_QUERY_XCMD -p state python3-devel
	# But it render many false positive
	case "${makedepends}" in
		*python3-devel*) ;;
		*) return 0 ;;
	esac
	_rx="[[:space:]]*NEEDED[[:space:]]*libpython${py3_ver//./[.]}"
	while read -r _file; do
		if ! read -r -n4 _elf <"$_file"; then
			:
		elif [ "$_elf" = $'\177ELF' ]; then
			_have_elf=yes
			if $OBJDUMP -p "$_file" 2>/dev/null | grep -q "$_rx"
			then
				return 0
			fi
		fi
	done < <(find "${DESTDIR}"/usr/bin \
		"${DESTDIR}"/usr/lib \
		"${DESTDIR}"/usr/libexec \
		-type f 2>/dev/null || true)

	if [ "$_have_elf" ]; then
		msg_error "$pkgname: not linked to libpython${py3_ver} but python3-devel in \$makedepends\n"
	fi
}
