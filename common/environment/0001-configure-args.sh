# This file sets up configure_args with commong settings for packages
# that don't set $build_style or set it to gnu-configure.

if [ "$build_style" = "gnu-configure" -o -z "$build_style" ]; then
	export configure_args="--prefix=/usr --sysconfdir=/etc --infodir=/usr/share/info --mandir=/usr/share/man --localstatedir=/var  ${configure_args}"
fi
