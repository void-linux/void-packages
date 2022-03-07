#
# This helper is for templates built using Haskell stack.
#
# make_build_args="stack-build-flags"
# stackage="lts-X.Y"  # or include a stack.yaml in $FILESDIR
#
do_build() {
	# use --skip-ghc-check to really force stack to use the ghc in the system
	# --system-ghc still downloads if stackage ghc version does not match ours
	# this fails on all platforms other than x86_64 glibc when we bump ghc
	local _stack_args="--system-ghc --skip-ghc-check"

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
		STACK_ROOT="$wrksrc/.stack" \
			stack init ${_stack_args} --force --resolver ${stackage}
	fi

	STACK_ROOT="$wrksrc/.stack" stack ${_stack_args} ${makejobs} build \
		${make_build_args}
}

do_install() {
	local _stack_args="--system-ghc --skip-ghc-check"

	vmkdir usr/bin
	STACK_ROOT="$wrksrc/.stack" stack ${_stack_args} install \
	       	${make_build_args} --local-bin-path=${DESTDIR}/usr/bin
}
