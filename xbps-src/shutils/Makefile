include ../vars.mk

.PHONY: clean
clean:
	-rm -f $(SCRIPTS)

.PHONY: install
install:
	install -d $(DESTDIR)$(SHAREDIR)/shutils
	install -m 644 *.sh $(DESTDIR)$(SHAREDIR)/shutils

.PHONY: uninstall
uninstall:
	-rm -rf $(DESTDIR)$(SHAREDIR)/shutils
