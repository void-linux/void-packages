do_build() {
	local f p
	mkdir -p "build/usr/share/texmf-dist"
	find . -maxdepth 1 -print -name "*.tar.xz" \
		-exec bsdtar -C "build/usr/share/texmf-dist" -xf {} \;
	cd "build/usr/share/texmf-dist/"
	if [ -d "texmf-dist" ] ; then
		rsync -ar texmf-dist/ ./
		rm -rf texmf-dist/
	fi
	rm -f LICENSE*
	while IFS=' ' read -r f p ; do
		if [ "$p" = "$pkgname" ] && ! [ -e "$f" ]; then
			msg_error "$pkgver: missing file $f\n"
		elif [ "$p" != "$pkgname" ] && [ -e "$f" ]; then
			echo "removed $f"
			mkdir -p ../texlive/removed
			echo "$f" >> ../texlive/removed/$pkgname.txt
			rm -f "$f"
		fi
	done < "${XBPS_COMMONDIR}/environment/build-style/texmf/ownership.txt"
}

do_check() {
	local f p exitcode=0
	cd build
	while read p; do
		if [[ ${p%-*} =~ .*-bin$ ]] || [ "${p%-*}" = "$pkgname" ]; then
			continue
		fi
		echo checking conflicts with ${p}...
		while IFS= read -r f; do
			if [ -e ".$f" ]; then
				msg_red "both contain file $f\n"
				exitcode=1
			fi
		done < <(xbps-query -Rf $p | sed 's/ -> .*//')
	done < <(xbps-query -Rs texlive -p pkgver | cut -d : -f 1)
	return $exitcode
}

do_install() {
	vcopy build/usr .
}
