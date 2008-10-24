#
# As specified in the LFS book, disable installing libiberty.
#
sed -i 's/install_to_$(INSTALL_DEST) //' $wrksrc/libiberty/Makefile.in
