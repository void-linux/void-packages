#
# gir - build-helper for gobject-introspection
#
# This build-helper is used for packages that make use of
# the GObject introspection middleware layer.
# 

# Check if the 'gir' build_option is set or if there is no
# 'gir' build_option.
if [ "$build_option_gir" ] || [[ $build_options != *"gir"* ]]; then
	# Provide the host tooling, g-ir-scanner, g-ir-compiler and its
	# wrappers.
	hostmakedepends+=" gobject-introspection"
	
	if [ "$CROSS_BUILD" ]; then
		# Required for running binaries produced from g-ir-compiler
		# via g-ir-scanner-qemuwrapper
		hostmakedepends+=" qemu-user-static"
	
		# Required for running the g-ir-scanner-lddwrapper
		hostmakedepends+=" prelink-cross"

		# Provide basic .gir types like GLib, GObject, DBus, Gio, cairo
		# and tooling like g-ir-compiler
		makedepends+=" gobject-introspection"
	fi
fi
