# xbps-packages top-level Makefile.
#
# MUTABLE VARIABLES
PRIVILEGED_GROUP ?= xbuilder

# INMUTABLE VARIABLES
VERSION	= 112
GITVER	:= $(shell git rev-parse --short HEAD)
SHAREDIR = common/xbps-src/shutils
LIBEXECDIR = common/xbps-src/libexec

CHROOT_C = uchroot.c
CHROOT_BIN = xbps-src-chroot-helper
CFLAGS += -O2 -Wall -Werror

.PHONY: all setup clean

all:
	sed -e "s|@@XBPS_SRC_VERSION@@|$(VERSION) ($(GITVER))|g"	\
		${CURDIR}/common/xbps-src/xbps-src.sh > ${CURDIR}/xbps-src
	$(CC) $(CFLAGS) ${LIBEXECDIR}/$(CHROOT_C) -o ${LIBEXECDIR}/$(CHROOT_BIN)
	chmod 755 xbps-src
	@echo
	@echo "The chroot helper must be a setgid binary (4750) for the group '$(PRIVILEGED_GROUP)'."
	@echo "Please run 'sudo make setup' to set appropiate permissions."

setup:
	chown root:$(PRIVILEGED_GROUP) $(LIBEXECDIR)/$(CHROOT_BIN)
	chmod 4750 $(LIBEXECDIR)/$(CHROOT_BIN)

clean:
	rm -f xbps-src $(LIBEXECDIR)/$(CHROOT_BIN)
