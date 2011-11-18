include ../vars.mk

SCRIPTS = chroot-helper.sh doinst-helper.sh
MOUNT_BIN = capmount
UMOUNT_BIN = capumount
CHROOT_BIN = capchroot
BINS = $(CHROOT_BIN) $(MOUNT_BIN) $(UMOUNT_BIN)
WFLAGS = -Wall -Werror
LDFLAGS = -lcap

ifdef IN_CHROOT
BINS =
SCRIPTS = doinst-helper.sh
endif

.PHONY: all
all: $(BINS)

.PHONY: clean
clean:
	-rm -f $(BINS)

.PHONY: install
install:
	install -d $(DESTDIR)$(LIBEXECDIR)
	for bin in $(SCRIPTS); do					\
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
	for bin in $(BINS) $(SCRIPTS); do			\
		rm -f $(DESTDIR)$(LIBEXECDIR)/$$bin;		\
	done

$(MOUNT_BIN):
	$(CC) $(WFLAGS) mount.c $(LDFLAGS) -o $@

$(UMOUNT_BIN):
	$(CC) $(WFLAGS) umount.c $(LDFLAGS) -o $@

$(CHROOT_BIN):
	$(CC) $(WFLAGS) chroot.c $(LDFLAGS) -o $@
