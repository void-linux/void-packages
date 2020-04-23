# This hook install $license_file

hook() {
	local pair file target
	cd "$wrksrc" || return 0
	for pair in $license_file
	do
		file=${pair%:*}
		if [ "$file" = "$pair" ]; then
			target=
		else
			target=${pair#*:}
		fi
		vlicense "$file" "$target"
	done
}
