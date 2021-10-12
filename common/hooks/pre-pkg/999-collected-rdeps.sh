# This hook displays resolved dependencies for a pkg.

hook() {
	if [ -e $PKGDESTDIR/rdeps ]; then
		echo "   $(cat $PKGDESTDIR/rdeps)"
	fi
}
