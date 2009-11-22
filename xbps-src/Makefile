include vars.mk

BIN	= xbps-src
SUBDIRS	= etc common helpers triggers shutils

.PHONY: all
all:
	sed -e	"s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"		\
	    -e	"s|@@XBPS_INSTALL_ETCDIR@@|$(ETCDIR)|g"		\
	    -e  "s|@@XBPS_INSTALL_SHAREDIR@@|$(SHAREDIR)|g"	\
		$(BIN).sh.in > $(BIN)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir || exit 1;	\
	done

.PHONY: clean
clean:
	-rm -f $(BIN)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir clean || exit 1;	\
	done

.PHONY: install
install: all
	install -d $(SBINDIR)
	install -m 755 $(BIN) $(SBINDIR)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir install || exit 1;	\
	done

.PHONY: uninstall
uninstall:
	-rm -f $(SBINDIR)/$(BIN)
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir uninstall || exit 1;	\
	done
