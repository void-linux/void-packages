include ../vars.mk

# Find out the real path for the xbps-src distribdir.
_CURDIR = $(shell dirname $(shell pwd))
ifeq ($(shell basename ${_CURDIR}), xbps-src)
DISTRIBDIR = $(subst /xbps-src,,${_CURDIR})
else
DISTRIBDIR = ${_CURDIR}
endif

CONF_FILE = xbps-src.conf

.PHONY: all
all:
	sed -e "s|@@XBPS_DISTRIBDIR@@|${DISTRIBDIR}|" \
		${CONF_FILE}.in > ${CONF_FILE}

.PHONY: clean
clean:
	-rm -f ${CONF_FILE}

.PHONY: install
install:
	if [ ! -d $(DESTDIR)$(ETCDIR) ]; then		\
		install -d $(DESTDIR)$(ETCDIR);		\
	fi
	if [ ! -f $(DESTDIR)$(ETCDIR)/$(CONF_FILE) ]; then 	\
		install -m644 $(CONF_FILE) $(DESTDIR)$(ETCDIR); \
	fi

.PHONY: uninstall
uninstall:
