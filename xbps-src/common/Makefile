include ../vars.mk

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: install
install:
	install -d $(DESTDIR)$(SHAREDIR)/common
	install -m 644 *.sh $(DESTDIR)$(SHAREDIR)/common

.PHONY: uninstall
uninstall:
	-rm -rf $(DESTDIR)$(SHAREDIR)/common
