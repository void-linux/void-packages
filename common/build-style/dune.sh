#
# This helper is for templates using OCaml's dune build system.
#
do_build() {
	: ${make_cmd:=dune}
	: ${make_build_target:=@install}

	"${make_cmd}" build --release $makejobs $make_build_args $make_build_target
}

do_check() {
	: ${make_cmd:=dune}
	: ${make_check_target:=@runtest}

	"${make_cmd}" build $makejobs $make_check_args $make_check_target
}

do_install() {
	: ${make_cmd:=dune}

	"${make_cmd}" install \
		--prefix="/usr" \
		--libdir="/usr/lib/ocaml" \
		--mandir="/usr/share/man" \
		--destdir="$DESTDIR" \
		$make_install_args $make_install_target

	# patch: mv /usr/doc to /usr/share/doc because dune does not provide way to
	# customize doc install path
	if [ -e "$DESTDIR/usr/doc" ]; then
		mkdir -p "$DESTDIR/usr/share"
		mv "$DESTDIR/usr/doc" "$DESTDIR/usr/share"
	fi
}
