# This hook generates XBPS configuration files for virtual packages.

hook() {
	local _tmpf

	# If package provides virtual packages, create dynamically the
	# required configuration file.
	if [ -n "$provides" ]; then
		_tmpf=$(mktemp) || msg_error "$pkgver: failed to create tempfile.\n"
		echo "# Virtual packages provided by '${pkgname}':" >>${_tmpf}
		for f in ${provides}; do
			echo "virtualpkg=${f}:${pkgname}" >>${_tmpf}
		done
		install -Dm644 ${_tmpf} ${PKGDESTDIR}/usr/share/xbps/virtualpkg.d/${pkgname}.conf
		rm -f ${_tmpf}
	fi
}
