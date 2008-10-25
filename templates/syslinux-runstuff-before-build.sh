#
# Disable looking for this file which causes an error.
#
sed -i -e 's|win32/syslinux.exe||g' $wrksrc/Makefile
