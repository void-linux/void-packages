if [ "$CROSS_BUILD" ]; then
	export WX_CONFIG=${XBPS_WRAPPERDIR}/wx-config-gtk3
else
	export WX_CONFIG=/usr/bin/wx-config-gtk3
fi
configure_args+=" -DwxWidgets_CONFIG_EXECUTABLE=${WX_CONFIG} "
