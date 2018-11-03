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

		local _TARGET_PLATFORM

		_TARGET_PLATFORM="$(ruby -r \
			$(find ${XBPS_CROSS_BASE}/usr/lib/ruby -iname rbconfig.rb) \
			-e 'puts RbConfig::CONFIG["arch"]' 2>/dev/null)"

		# Patch all instances of extconf that use create_makefile
		for f in $(find . -type f -name 'extconf.rb'); do
			if [ ! -f ${f}.orig ]; then
				# Create a .extconf file that forces the Makefile to use our environment
				# this allows us to cross-compile like it is done with meson cross-files
				cat<<EOF>append
\$CPPFLAGS = ENV['CPPFLAGS'] if ENV['CPPFLAGS']
RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']
RbConfig::MAKEFILE_CONFIG['CXX'] = ENV['CXX'] if ENV['CXX']
RbConfig::MAKEFILE_CONFIG['LD'] = ENV['LD'] if ENV['LD']
RbConfig::MAKEFILE_CONFIG['CFLAGS'] = ENV['CFLAGS'] if ENV['CFLAGS']
RbConfig::MAKEFILE_CONFIG['CPPFLAGS'] = ENV['CPPFLAGS'] if ENV['CPPFLAGS']
RbConfig::MAKEFILE_CONFIG['CXXFLAGS'] = ENV['CXXFLAGS'] if ENV['CXXFLAGS']
EOF
				cat $f > append2
				# Use sed and enable verbose mode
				cat<<EOF>>append2
system("sed -i 's|^V =.*|V = 1|' Makefile")
system("sed -i 's|^CFLAGS.*|CFLAGS = \$(CCDLFLAGS) ${VOID_TARGET_CFLAGS} \$(ARCH_FLAG)|' Makefile")
system("sed -i 's|^topdir.*|topdir = ${XBPS_CROSS_BASE}/usr/include/ruby-\$(ruby_version)|' Makefile")
system("sed -i 's|^hdrdir.*|hdrdir = ${XBPS_CROSS_BASE}/usr/include/ruby-\$(ruby_version)|' Makefile")
system("sed -i 's|^arch_hdrdir.*|arch_hdrdir = ${XBPS_CROSS_BASE}/usr/include/ruby-\$(ruby_version)/\$(arch)|' Makefile")
system("sed -i 's|^arch =.*|arch = ${_TARGET_PLATFORM}|' Makefile")
system("sed -i 's|^dldflags =.*|dldflags = ${LDFLAGS}|' Makefile")
EOF

				# Create a backup which we will restore later
				cp $f ${f}.orig

				# Patch extconf.rb for cross compile
				cat append append2 > $f
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

	local _GEMDIR _INSTDIR

	_GEMDIR=$($gem_cmd env gemdir)
	_INSTDIR=${DESTDIR}/${_GEMDIR}/gems/${pkgname#ruby-}-${version}

	# Ruby is very eager to add CFLAGS everywhere there is a compilation
	# but we do both cross compilation of the modules and host compilation
	# for checks, so unset CFLAGS and keep it in a separate value.
	# We will manually pass CFLAGS as VOID_TAGET_CFLAGS to cross-compilation
	# And ruby will use rbconfig.rb to get the proper CFLAGS for host compilation
	VOID_TARGET_CFLAGS="$CFLAGS"
	export VOID_TARGET_CFLAGS
	unset CFLAGS

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
	if [ -d ${_INSTDIR}/man ]; then
		find ${_INSTDIR}/man -type f -name '*.[0-8n]' | while read -r m; do
			vman ${m}
		done
	fi

	rm -rf "${_INSTDIR}/man"

	# Place executables in /usr/bin
	if [ -d "${_INSTDIR}/bin" ]; then
		for f in "${_INSTDIR}"/bin/*; do
			vbin "${f}"
		done
	fi

	rm -rf ${_INSTDIR}/bin

	# Place conf files in their places
	if [ -d ${_INSTDIR}/etc ]; then
		find ${_INSTDIR}/etc -type f | while read -r c; do
			vmkdir $(dirname ${c})
			mv ${c} "${DESTDIR}/${c##*${_INSTDIR}/etc/}/"
		done
	fi

	rm -rf ${_INSTDIR}/etc

	if [ "$CROSS_BUILD" ]; then

		local _TARGET_PLATFORM _TARGET_EXT_DIR
		
		# Get arch of the target and host platform by reading the rbconfig.rb
		# of the cross ruby
		_TARGET_PLATFORM="$(ruby -r \
			$(find ${XBPS_CROSS_BASE}/usr/lib/ruby -iname rbconfig.rb) \
			-e 'puts RbConfig::CONFIG["arch"]' 2>/dev/null)"

		# Path to the extensions on a package, ruby installs against the platform
		# of the host, so we have to move them to the correct place
		_TARGET_EXT_DIR="${DESTDIR}/${_GEMDIR}/extensions/${_TARGET_PLATFORM}"

		find ${DESTDIR}/${_GEMDIR}/extensions -maxdepth 1 -type d \
			-exec mv '{}' ${_TARGET_EXT_DIR} \;
	fi
}
