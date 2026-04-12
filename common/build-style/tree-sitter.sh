#
# This helper is for templates using building tree-sitter grammars.
#
do_build() {
	: "${treesitter_src:=./src}"
	CFLAGS="-fPIC -Wall -I ./ -std=c99 $CFLAGS"
	CXXFLAGS="-fPIC -Wall -I ./ -fno-exceptions $CXXFLAGS"
	LDFLAGS="-shared $LDFLAGS"

	if [ -z "${treesitter_lang}" ]; then
		treesitter_lang="$(jq -re '.name' "${treesitter_src}/grammar.json")"
	fi

	cd "$treesitter_src"

	msg_verbose "$CC $CFLAGS -c ./*.c\n"
	$CC $CFLAGS -c ./*.c
	if compgen -G "./*.cc"; then
		msg_verbose "$CXX $CXXFLAGS -c ./*.cc\n"
		$CXX $CXXFLAGS -c ./*.cc
		msg_verbose "$CXX $LDFLAGS -o "$treesitter_lang.so" ./*.o\n"
		$CXX $LDFLAGS -o "$treesitter_lang.so" ./*.o
	else
		msg_verbose "$CC $LDFLAGS -o "$treesitter_lang.so" ./*.o\n"
		$CC $LDFLAGS -o "$treesitter_lang.so" ./*.o
	fi
	unset treesitter_lang
}

do_check() {
	tree-sitter test
}

do_install() {
	: "${treesitter_src:=./src}" "${treesitter_queries:=./queries}"

	if [ -z "${treesitter_lang}" ]; then
		treesitter_lang="$(jq -re '.name' "${treesitter_src}/grammar.json")"
	fi

	# Some programs expect grammar libs as <lang>.so in a specific
	# directory, some expect libtree-sitter-<lang>.so on the library path.
	vinstall "${treesitter_src}/${treesitter_lang}.so" 755 "usr/lib/tree-sitter"
	ln -s "tree-sitter/${treesitter_lang}.so" "${DESTDIR}/usr/lib/libtree-sitter-${treesitter_lang}.so"

	if [ -d "${treesitter_queries}" ] && compgen -G "./${treesitter_queries}/*.scm"; then
		vmkdir "usr/share/tree-sitter/queries/${treesitter_lang}"
		vcopy "${treesitter_queries}/*.scm" "usr/share/tree-sitter/queries/${treesitter_lang}"
	elif [ -d "${treesitter_queries}/${treesitter_lang}" ] && compgen -G "./${treesitter_queries}/${treesitter_lang}/*.scm"; then
		vmkdir "usr/share/tree-sitter/queries/${treesitter_lang}"
		vcopy "${treesitter_queries}/${treesitter_lang}/*.scm" "usr/share/tree-sitter/queries/${treesitter_lang}"
	fi
	unset treesitter_lang
}
