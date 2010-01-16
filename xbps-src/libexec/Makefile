include ../vars.mk

BINS	= xbps-src-chroot-helper xbps-src-doinst-helper

.PHONY: all
all:
	for bin in $(BINS); do						\
		sed -e	"s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"		\
		    -e	"s|@@XBPS_INSTALL_ETCDIR@@|$(ETCDIR)|g"		\
		    -e  "s|@@XBPS_INSTALL_SHAREDIR@@|$(SHAREDIR)|g"	\
		    -e  "s|@@XBPS_INSTALL_SBINDIR@@|$(SBINDIR)|g"	\
			$$bin.sh.in > $$bin;				\
	done

.PHONY: clean
clean:
	-rm -f $(BINS)

.PHONY: install
install: all
	install -d $(DESTDIR)$(LIBEXECDIR)
	for bin in $(BINS); do					\
		install -m 755 $$bin $(DESTDIR)$(LIBEXECDIR);	\
	done

.PHONY: uninstall
uninstall:
	for bin in $(BINS); do					\
		rm -f $(DESTDIR)$(LIBEXECDIR)/$$bin;		\
	done
