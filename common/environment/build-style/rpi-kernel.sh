_kernver="${version}_${revision}"

nodebug=yes
nostrip=yes
noverifyrdeps=yes
noshlibprovides=yes

triggers="kernel-hooks"
# These files could be modified when an external module is built.
mutable_files="
	/usr/lib/modules/${_kernver}/modules.dep
	/usr/lib/modules/${_kernver}/modules.dep.bin
	/usr/lib/modules/${_kernver}/modules.symbols
	/usr/lib/modules/${_kernver}/modules.symbols.bin
	/usr/lib/modules/${_kernver}/modules.alias
	/usr/lib/modules/${_kernver}/modules.alias.bin
	/usr/lib/modules/${_kernver}/modules.devname"

_arch=
case "$XBPS_TARGET_MACHINE" in
	arm*) _arch=arm ;;
	aarch64*) _arch=arm64 ;;
esac
_cross=
if [ "$CROSS_BUILD" ]; then
	_cross="CROSS_COMPILE=${XBPS_CROSS_TRIPLET}-"
fi

python_version=3
