TOPDIR = ../..
include $(TOPDIR)/vars.mk

BIN = xbps-src

.PHONY: all
all:
	sed -e "s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g" main.sh > xbps-src

.PHONY: clean
clean: clean-bins

clean-bins:
	-rm -f $(BIN)

install: $(BIN)
	install -d $(SBINDIR)
	install -m 755 $(BIN) $(SBINDIR)
