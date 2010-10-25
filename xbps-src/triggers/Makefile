include ../vars.mk

TRIGGERS=	gtk-icon-cache info-files mimedb register-shell
TRIGGERS+=	xml-catalog gtk-immodules initramfs-tools openrc-service
TRIGGERS+=	update-desktopdb gtk-pixbuf-loaders pango-modules x11-fonts
TRIGGERS+=	system-accounts gconf-schemas gio-modules gsettings-schemas

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: install
install:
	install -d $(DESTDIR)$(SHAREDIR)/triggers
	install -m 755 $(TRIGGERS) $(DESTDIR)$(SHAREDIR)/triggers

.PHONY: uninstall
uninstall:
	-rm -rf $(DESTDIR)$(SHAREDIR)/triggers
