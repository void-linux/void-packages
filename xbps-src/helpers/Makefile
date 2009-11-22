include ../vars.mk

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: install
install:
	install -d $(DESTDIR)$(SHAREDIR)/helpers
	install -m 644 *.sh $(DESTDIR)$(SHAREDIR)/helpers

.PHONY: uninstall
uninstall:
	-rm -rf $(DESTDIR)$(SHAREDIR)/helpers
