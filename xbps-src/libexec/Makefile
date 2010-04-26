include ../vars.mk

SH_BINS = xbps-src-chroot-helper xbps-src-doinst-helper
MOUNT_BIN = xbps-src-chroot-capmount
UMOUNT_BIN = xbps-src-chroot-capumount
CHROOT_BIN = xbps-src-capchroot
BINS = $(CHROOT_BIN) $(MOUNT_BIN) $(UMOUNT_BIN)
WFLAGS = -Wall -Werror
LDFLAGS = -lcap

ifdef IN_CHROOT
BINS =
endif

.PHONY: all
all: $(BINS)
	for bin in $(SH_BINS); do					\
		sed -e	"s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"		\
		    -e	"s|@@XBPS_INSTALL_ETCDIR@@|$(ETCDIR)|g"		\
		    -e  "s|@@XBPS_INSTALL_SHAREDIR@@|$(SHAREDIR)|g"	\
		    -e  "s|@@XBPS_INSTALL_SBINDIR@@|$(SBINDIR)|g"	\
		    -e	"s|@@XBPS_INSTALL_LIBEXECDIR@@|$(LIBEXECDIR)|g"	\
			$$bin.sh.in > $$bin;				\
	done

.PHONY: clean
clean:
	-rm -f $(BINS) $(SH_BINS)

.PHONY: install
install: all
	install -d $(DESTDIR)$(LIBEXECDIR)
	for bin in $(SH_BINS); do					\
		install -m755 $$bin $(DESTDIR)$(LIBEXECDIR);		\
	done
ifdef BINS
	install -m755 $(MOUNT_BIN) $(DESTDIR)$(LIBEXECDIR)
	setcap cap_sys_admin=ep $(DESTDIR)$(LIBEXECDIR)/$(MOUNT_BIN)
	install -m755 $(UMOUNT_BIN) $(DESTDIR)$(LIBEXECDIR)
	setcap cap_sys_admin=ep $(DESTDIR)$(LIBEXECDIR)/$(UMOUNT_BIN)
	install -m755 $(CHROOT_BIN) $(DESTDIR)$(LIBEXECDIR)
	setcap cap_sys_chroot=ep $(DESTDIR)$(LIBEXECDIR)/$(CHROOT_BIN)
endif

.PHONY: uninstall
uninstall:
	for bin in $(BINS) $(SH_BINS); do			\
		rm -f $(DESTDIR)$(LIBEXECDIR)/$$bin;		\
	done

$(MOUNT_BIN):
	$(CC) $(WFLAGS) $(LDFLAGS) mount.c -o $@

$(UMOUNT_BIN):
	$(CC) $(WFLAGS) $(LDFLAGS) umount.c -o $@

$(CHROOT_BIN):
	$(CC) $(WFLAGS) $(LDFLAGS) chroot.c -o $@
