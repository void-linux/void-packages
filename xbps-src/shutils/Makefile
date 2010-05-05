include ../vars.mk

SCRIPTS = tmpl_funcs.sh chroot.sh init_funcs.sh pkgtarget_funcs.sh

.PHONY: all
all:
	for f in $(SCRIPTS); do						\
		sed -e "s|@@XBPS_INSTALL_PREFIX@@|$(PREFIX)|g"		\
		    -e "s|@@XBPS_INSTALL_SHAREDIR@@|$(SHAREDIR)|g"	\
		    -e "s|@@XBPS_INSTALL_LIBEXECDIR@@|$(LIBEXECDIR)|g"	\
		    $$f.in > $$f;					\
	done

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
