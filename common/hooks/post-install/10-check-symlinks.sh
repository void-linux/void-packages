# This hook checks for broken symlinks.

hook() {
	local target symlink
	while read -r symlink; do
		target=$(realpath --relative-to="${PKGDESTDIR}" --relative-base="${PKGDESTDIR}" -m $symlink)
		if [ ! -e "${PKGDESTDIR}/${target}" ]; then
			echo "   Symlink missing target: ${symlink#${PKGDESTDIR}} -> ${target}"
		fi
	done < <(find ${PKGDESTDIR} -type l -follow -not -path "${PKGDESTDIR}/etc/sv/*")
}
