include vars.mk

SUBDIRS	= lib bin

.PHONY: all
all:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir;		\
	done

.PHONY: install
install:
	install -D xbps-src.sh $(BINDIR)/xbps-src
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir install;	\
	done

uninstall:
	-rm -f $(BINDIR)/xbps-*

.PHONY: clean
clean:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir clean;		\
	done
