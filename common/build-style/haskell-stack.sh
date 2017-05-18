#
# This helper is for templates built using Haskell stack.
#
# make_build_args="stack-build-flags"
# stackage="lts-X.Y"  # or include a stack.yaml in $FILESDIR
#
do_build() {
	if [ -f "${FILESDIR}/stack.yaml" ]; then
		msg_normal "Using stack config in stack.yaml.\n"
		cp "${FILESDIR}/stack.yaml" .
	elif [ -z "$stackage" -a -f "stack.yaml" ]; then
		msg_normal "Using stack.yaml from downloaded source.\n"
	else
		if [ -z "$stackage" ]; then
			msg_error "Stackage version not set in \$stackage.\n"
		fi
		msg_normal "Using stackage resolver ${stackage}.\n"
		STACK_ROOT=$wrksrc/.stack \
			stack init --force --resolver ${stackage}
	fi

	STACK_ROOT=$wrksrc/.stack stack --system-ghc ${makejobs} build \
		${make_build_args}
}

do_install() {
	vmkdir usr/bin
	STACK_ROOT=$wrksrc/.stack stack --system-ghc install \
	       	${make_build_args} --local-bin-path=${DESTDIR}/usr/bin
}
