#
# This helper is for templates using gemspec files from upstream or Rubygems.
#
do_build() {
	: ${gem_cmd:=gem}
	: ${gemspec:=${pkgname#ruby-}.gemspec}

	# Fix packages that keep Gem.gemspec as the name instead of the proper
	# $pkgname.gemspec
	if [ -f Gem.gemspec ]; then
		gemspec=Gem.gemspec
	fi

	if [ -f .gemspec ]; then
		gemspec=.gemspec
	fi

	# Hardcode name and version just in case they try something funny like
	# requiring RELEASE to be on the environment to not append -rc0 to version
	# Some even forget to update the version in the gemspec after releasing
	sed -ri "s|(\.name .*)=.*|\1 = \"${pkgname#ruby-}\"|g" $gemspec
	sed -ri "s|(\.version .*)=.*|\1 = \"${version}\"|g" $gemspec

	# Replace use of `git ls-files` with find, use printf so we can print without starting
	# dot-slash path
	sed -i 's|`git ls-files`|`find . -type f -printf "%P\\n"`|g' $gemspec

	# Sadly ruby isn't capable of handling nullbytes in a command so we have to use
	# -print0, then try using sed to remove the suffix
	# The end result is:
	# `find . -type f -print0 | sed -e "s@\\./@@g"`
	sed -i 's|`git ls-files -z`|`find . -type f -print0 \| sed -e "s@\\\\./@@g"`|g' $gemspec

	if [ "$CROSS_BUILD" ]; then
		# Create a .extconf file that forces the Makefile to use our environment
		# this allows us to cross-compile like it is done with meson cross-files
		cat>append<<EOF
RbConfig::MAKEFILE_CONFIG['CPPFLAGS'] = ENV['CPPFLAGS'] if ENV['CPPFLAGS']
\$CPPFLAGS = ENV['CPPFLAGS'] if ENV['CPPFLAGS']
RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']
RbConfig::MAKEFILE_CONFIG['CXX'] = ENV['CXX'] if ENV['CXX']
RbConfig::MAKEFILE_CONFIG['LD'] = ENV['LD'] if ENV['LD']
RbConfig::MAKEFILE_CONFIG['CFLAGS'] = ENV['CFLAGS'] if ENV['CFLAGS']
RbConfig::MAKEFILE_CONFIG['CXXFLAGS'] = ENV['CXXFLAGS'] if ENV['CXXFLAGS']
RbConfig::MAKEFILE_CONFIG['AR'] = ENV['AR'] if ENV['AR']
RbConfig::MAKEFILE_CONFIG['RANLIB'] = ENV['RANLIB'] if ENV['RANLIB']
EOF

		# Patch all instances of extconf that use create_makefile
		for f in $(find . -type f -name 'extconf.rb'); do
			if [ ! -f ${f}.orig ]; then
				# Ignore extconf files that do not create makefiles
				grep -q create_makefile $f || continue
				# Create a backup which we will restore later
				cp $f ${f}.orig
				# Patch extconf.rb for cross compile
				cat append ${f}.orig >> $f
			fi
		done
	fi

	# If we are downloading a gem file then create a spec out of it
	for f in $distfiles; do
		if [ "${f##*.}" = "gem" ]; then
			$gem_cmd spec \
				"${XBPS_SRCDISTDIR}/${pkgname}-${version}/${f##*/}" \
				--ruby > $gemspec
		fi
	done

	$gem_cmd build --verbose ${gemspec}

	if [ "$CROSS_BUILD" ]; then
		# Restore previous extconf.rb which we ship.
		find . -type f -name 'extconf.rb.orig' | while read -r f; do
			mv $f ${f%.*}
		done
	fi
}

do_install() {
	: ${gem_cmd:=gem}

	local _GEMDIR _INSTDIR _TARGET_PLATFORM _HOST_PLATFORM _HOST_EXT_DIR _TARGET_EXT_DIR

	_GEMDIR=$($gem_cmd env gemdir)
	_INSTDIR=${DESTDIR}/${_GEMDIR}/gems/${pkgname#ruby-}-${version}

	if [ "$CROSS_BUILD" ]; then
		# Convert to the platforms used in our ruby packages
		case "$XBPS_TARGET_MACHINE" in
			x86_64) _TARGET_PLATFORM=x86_64-linux ;;
			x86_64-musl) _TARGET_PLATFORM=x86_64-linux-musl ;;
			i686) _TARGET_PLATFORM=i686-linux ;;
			i686-musl) _TARGET_PLATFORM=i686-linux-musl ;;
			armv7l|armv7hf) _TARGET_PLATFORM=armv7l-linux-eabihf ;;
			armv6l|armv6hf) _TARGET_PLATFORM=arm-linux-eabihf ;;
			armv7l-musl|armv7hf-musl) _TARGET_PLATFORM=armv7l-linux-musleabihf ;;
			armv6l-musl|armv6hf-musl) _TARGET_PLATFORM=arm-linux-musleabihf ;;
			aarch64) _TARGET_PLATFORM=aarch64-linux ;;
			aarch64-musl) _TARGET_PLATFORM=aarch64-linux-musl ;;
		esac

		case "$XBPS_MACHINE" in
			x86_64) _HOST_PLATFORM=x86_64-linux ;;
			x86_64-musl) _HOST_PLATFORM=x86_64-linux-musl ;;
			i686) _HOST_PLATFORM=i686-linux ;;
			i686-musl) _HOST_PLATFORM=i686-linux-musl ;;
			armv7l|armv7hf) _HOST_PLATFORM=armv7l-linux-eabihf ;;
			armv6l|armv6hf) _HOST_PLATFORM=arm-linux-eabihf ;;
			armv7l-musl|armv7hf-musl) _HOST_PLATFORM=armv7l-linux-musleabihf ;;
			armv6l-musl|armv6hf-musl) _HOST_PLATFORM=arm-linux-musleabihf ;;
			aarch64) _HOST_PLATFORM=aarch64-linux ;;
			aarch64-musl) _HOST_PLATFORM=aarch64-linux-musl ;;
		esac
	fi

	$gem_cmd install \
		--local \
		--install-dir ${DESTDIR}/${_GEMDIR} \
		--bindir ${DESTDIR}/usr/bin \
		--ignore-dependencies \
		--no-document \
		--verbose \
		"${pkgname#ruby-}-${version}.gem" \
		-- $configure_args

	# Remove cache
	rm -rf ${DESTDIR}/${_GEMDIR}/cache

	# Remove ext directory, they are only source code and configuration
	# The actual extensions are in a arch path guarded
	rm -rf ${_INSTDIR}/ext

	# Remove duplicated library that is available in a arch guarded
	# extension
	rm -rf ${_INSTDIR}/lib/*.so

	# Remove installed tests and benchmarks
	rm -rf ${_INSTDIR}/{test,tests,autotest,benchmark,benchmarks,script,examples,demo}

	# Remove files shipped on the root of the gem, most of the time they are useless
	find ${_INSTDIR} -maxdepth 1 -type f -delete

	# Remove unnecessary files
	find ${DESTDIR}/${_GEMDIR}/extensions \( -name mkmf.log -o -name gem_make.out \) -delete

	# Place manpages in usr/share/man/man[0-9]
	find ${_INSTDIR}/man -type f -name '*.[0-8n]' | while read -r m; do
		vman ${m}
	done

	rm -rf "${_INSTDIR}/man"

	# Place executables in /usr/bin
	if [ -d "${_INSTDIR}/bin" ]; then
		for f in "${_INSTDIR}"/bin/*; do
			vbin "${f}"
		done
	fi

	rm -rf ${_INSTDIR}/bin

	# Place conf files in their places
	find ${_INSTDIR}/etc -type f | while read -r c; do
		vmkdir $(dirname ${c})
		mv ${c} "${DESTDIR}/${c##*${_INSTDIR}/etc/}/"
	done

	rm -rf ${_INSTDIR}/etc

	if [ "$CROSS_BUILD" ]; then
		# Path to the extensions on a package, ruby installs against the platform
		# of the host, so we have to move them to the correct place
		_HOST_EXT_DIR="${DESTDIR}/${_GEMDIR}/extensions/${_HOST_PLATFORM}"
		_TARGET_EXT_DIR="${DESTDIR}/${_GEMDIR}/extensions/${_TARGET_PLATFORM}"

		if [ -d ${_HOST_EXT_DIR} ]; then
			mv ${_HOST_EXT_DIR} ${_TARGET_EXT_DIR}
		fi

		# Fix Makefile locations to point to the correct platform
		for f in $(find ${DESTDIR}/${_GEMDIR} -type f -name 'Makefile'); do
			sed -i "s|${_HOST_PLATFORM}|${_TARGET_PLATFORM}|g" $f
		done
	fi
}
