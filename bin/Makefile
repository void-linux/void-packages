include ../vars.mk

SUBDIRS =	xbps-bin
SUBDIRS +=	xbps-cmpver
SUBDIRS +=	xbps-digest
SUBDIRS +=	xbps-pkgdb
SUBDIRS +=	xbps-repo
SUBDIRS +=	xbps-src

.PHONY: all
all:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir;		\
	done

.PHONY: install
install:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir install;	\
	done

.PHONY: clean
clean:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir clean;		\
	done
