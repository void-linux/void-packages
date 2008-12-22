include vars.mk

SUBDIRS	= lib bin

.PHONY: all
all:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir;		\
	done

.PHONY: install
install:
	install -D xbps-src.sh $(SBINDIR)/xbps-src
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir install;	\
	done
	@echo
	@echo "Binaries have been installed into $(SBINDIR)."
	@echo "Librares have been installed into $(LIBDIR)."
	@echo
	@echo "WARNING: Don't forget to rerun ldconfig(1)."
	@echo

uninstall:
	-rm -f $(SBINDIR)/xbps-*
	-rm -f $(LIBDIR)/libxbps.so*

.PHONY: clean
clean:
	for dir in $(SUBDIRS); do		\
		$(MAKE) -C $$dir clean;		\
	done
