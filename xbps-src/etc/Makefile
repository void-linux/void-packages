include ../vars.mk

CONF_FILE = xbps-src.conf

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: install
install:
	if [ ! -d $(DESTDIR)$(ETCDIR) ]; then		\
		install -d $(DESTDIR)$(ETCDIR);		\
	fi

	if [ ! -f $(DESTDIR)$(ETCDIR)/$(CONF_FILE) ]; then		\
		install -m 644 $(CONF_FILE) $(DESTDIR)$(ETCDIR);	\
	fi

.PHONY: uninstall
uninstall:
