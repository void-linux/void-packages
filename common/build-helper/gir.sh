#
# gir - build-helper for gobject-introspection
#
# This build-helper is used for packages that make use of
# the GObject introspection middleware layer.
# 

# Check if the 'gir' build_option is set or if there is no
# 'gir' build_option.
if [ "$build_option_gir" ] || [[ $build_options != *"gir"* ]]; then
	if [[ $hostmakedepends != *"gobject-introspection"* ]]; then
		# Provide the host tooling, g-ir-scanner, g-ir-compiler
		# and its wrappers.
		hostmakedepends+=" gobject-introspection"
	fi
	
	if [ "$CROSS_BUILD" ]; then
		# Required for running binaries produced from g-ir-compiler
		# via g-ir-scanner-qemuwrapper
		hostmakedepends+=" qemu-user-static"
	
		# Required for running the g-ir-scanner-lddwrapper
		hostmakedepends+=" prelink-cross"

		if [[ $makedepends != *"gobject-introspection"* ]]; then
			# Provide basic .gir types like GLib, GObject, DBus, Gio, cairo
			# and tooling like g-ir-compiler
			makedepends+=" gobject-introspection"
		fi

		export VAPIGEN_VAPIDIRS=${XBPS_CROSS_BASE}/usr/share/vala/vapi
		export VAPIGEN_GIRDIRS=${XBPS_CROSS_BASE}/usr/share/gir-1.0

		# Provide some packages in hostmakedepends if they are in makedepends
		for f in gtk+3-devel python3-gobject-devel; do
			if [[ $makedepends == *"${f}"* ]]; then
				hostmakedepends+=" ${f}"
			fi
		done
		unset f
	fi
fi
