if [ "$CROSS_BUILD" ]; then
	export WX_CONFIG=${XBPS_WRAPPERDIR}/wx-config-gtk3
else
	export WX_CONFIG=wx-config-gtk3
fi
