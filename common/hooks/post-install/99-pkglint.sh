# This hook checks for common issues related to void.

hook() {
	local error=0

	for f in bin sbin lib lib32; do
		if [ -d ${PKGDESTDIR}/${f} ]; then
			msg_red "${pkgver}: /${f} directory is not allowed, use /usr/${f}.\n"
			error=1
		fi
	done
	for f in sys dev home root run var/run tmp usr/lib64 usr/local; do
		if [ -d ${PKGDESTDIR}/${f} ]; then
			msg_red "${pkgver}: /${f} directory is not allowed, remove it!\n"
			error=1
		fi
	done
	if [ $error -gt 0 ]; then
		msg_error "${pkgver}: cannot continue with installation!\n"
	fi
}
