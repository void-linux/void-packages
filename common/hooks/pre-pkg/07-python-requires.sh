# This hook executes the following tasks:
#	- checks if python requires are satisfied

hook() {
	local requires= pver= req= reqname= modules= module= cmp=;

	if [ -e "$wrksrc/requirements.txt" ]; then
		requires=$(grep -v "^#.*" "$wrksrc/requirements.txt")
	elif [ -e "$wrksrc/setup.py" ]; then
		pver=${python_versions%% *}
	requires=$( ( cd "$wrksrc"; python$pver -c 'import setup; print("\n".join(setup.params["install_requires"]))') )
	else
		return 0
	fi

	# reads all dependencies and creates a list of modules
	modules=$(for dep in $depends; do
		(
			local _name=

			setup_pkg "$dep" "$XBPS_CROSS_BUILD" ignore-problems
			if [ -h "$XBPS_SRCPKGDIR/${pkgname}" ]; then
				"${pkgname}_package"
			fi

			printf "%s:%s:" ${pkgname}-${version}_${revision} "$pkgname"
			for _name in ${pycompile_module}; do
				_name="${_name//\//.}"
				printf "%s:" "${_name%.py}"
			done
			echo
		)
	done)

	# checks if all requires are satisfied by the depending modules
	for i in $requires; do
		req=${i/;*/}
		if ! reqname="$($XBPS_UHELPER_CMD getpkgdepname "${req}")"; then
			reqname=$_tmpreq
		fi

		if ! module=$(echo "$modules" | grep ":$reqname:"); then
			msg_warn "Python Dependency $req not found\n"
			msg_warn "  Full pattern: ${i}\n"
			continue
		fi
		cmp=$(echo "$req" | sed "s/[^<>=]*/$($XBPS_UHELPER_CMD getpkgname "${module%%:*}")/")
		if $XBPS_UHELPER_CMD pkgmatch "${module%%:*}" "$cmp"; then
			msg_warn "Python Dependency version mismatch: $cmp => ${module%%:*}\n"
		fi
	done
}
