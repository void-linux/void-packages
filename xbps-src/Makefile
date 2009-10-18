include vars.mk

BIN	= xbps-src
SUBDIRS	= etc shutils

.PHONY: all
all:
	sed -e	"s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"		\
	    -e	"s|@@XBPS_INSTALL_ETCDIR@@|$(ETCDIR)|g"		\
	    -e  "s|@@XBPS_INSTALL_SHAREDIR@@|$(SHAREDIR)|g"	\
		$(BIN).sh.in > $(BIN)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir;		\
	done

.PHONY: clean
clean:
	-rm -f $(BIN)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir clean;		\
	done

.PHONY: install
install: all
	install -d $(SBINDIR)
	install -m 755 $(BIN) $(SBINDIR)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir install;	\
	done

.PHONY: uninstall
uninstall:
	-rm -f $(SBINDIR)/$(BIN)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir uninstall;	\
	done
