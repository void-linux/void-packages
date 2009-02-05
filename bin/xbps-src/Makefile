TOPDIR = ../..
include $(TOPDIR)/vars.mk

BIN = xbps-src

.PHONY: all
all:
	sed -e	"s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"	\
	    -e	"s|@@XBPS_INSTALL_ETCDIR@@|$(ETCDIR)|g"	\
		main.sh > xbps-src

.PHONY: clean
clean:
	-rm -f $(BIN)

install: all
	install -d $(SBINDIR)
	install -m 755 $(BIN) $(SBINDIR)
