# Toplevel Makefile
#
.PHONY: all
all:
	$(MAKE) -C xbps-src

.PHONY: install
install:
	$(MAKE) -C xbps-src install

.PHONY: uninstall
uninstall:
	$(MAKE) -C xbps-src uninstall

.PHONY: clean
clean:
	$(MAKE) -C xbps-src clean
