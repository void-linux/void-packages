hostmakedepends+=" zig"

# GNU Binutils fails on programs compiled/linked (?) with llvm
# See: https://sourceware.org/bugzilla//show_bug.cgi?id=30237
#
if [ "${XBPS_TARGET_MACHINE/-musl/}" = "riscv64" ]; then
	hostmakedepends+=" llvm"
	OBJCOPY="llvm-objcopy"
	STRIP="llvm-strip"
fi
