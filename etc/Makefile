include ../vars.mk

CONF_FILE = xbps.conf

.PHONY: all
all:

.PHONY: clean
clean:

install:
	if [ ! -d $(ETCDIR) ]; then		\
		install -d $(ETCDIR);		\
	fi

	if [ ! -f $(ETCDIR)/$(CONF_FILE) ]; then	\
		install -m 644 $(CONF_FILE) $(ETCDIR);	\
	fi
