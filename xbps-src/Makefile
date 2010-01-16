include vars.mk

BINS	= xbps-src
SUBDIRS	= etc common libexec helpers triggers shutils

.PHONY: all
all:
	for bin in $(BINS); do						\
		sed -e	"s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"		\
		    -e	"s|@@XBPS_INSTALL_ETCDIR@@|$(ETCDIR)|g"		\
		    -e  "s|@@XBPS_INSTALL_SHAREDIR@@|$(SHAREDIR)|g"	\
		    -e  "s|@@XBPS_INSTALL_SBINDIR@@|$(SBINDIR)|g"	\
			$$bin.sh.in > $$bin;				\
	done
	for dir in $(SUBDIRS); do			\
		$(MAKE) -C $$dir || exit 1;		\
	done

.PHONY: clean
clean:
	-rm -f $(BINS)
	for dir in $(SUBDIRS); do			\
		$(MAKE) -C $$dir clean || exit 1;	\
	done

.PHONY: install
install: all
	install -d $(SBINDIR)
	for bin in $(BINS); do				\
		install -m 755 $$bin $(SBINDIR);	\
	done
	for dir in $(SUBDIRS); do			\
		$(MAKE) -C $$dir install || exit 1;	\
	done

.PHONY: uninstall
uninstall:
	for bin in $(BINS); do				\
		rm -f $(SBINDIR)/$$bin;			\
	done
	for dir in $(SUBDIRS); do			\
		$(MAKE) -C $$dir uninstall || exit 1;	\
	done
