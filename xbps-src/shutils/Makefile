include ../vars.mk

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: install
install:
	install -d $(DESTDIR)$(SHAREDIR)/shutils
	install -m 644 *.sh $(DESTDIR)$(SHAREDIR)/shutils

.PHONY: uninstall
uninstall:
	-rm -rf $(DESTDIR)$(SHAREDIR)/shutils
