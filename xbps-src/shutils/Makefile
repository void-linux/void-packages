include ../vars.mk

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: install
install:
	if [ ! -d $(DESTDIR)$(SHAREDIR) ]; then		\
		install -d $(DESTDIR)$(SHAREDIR);	\
	fi

	for f in *.sh; do					\
		install -m 755 $$f $(DESTDIR)$(SHAREDIR);	\
	done

.PHONY: uninstall
uninstall:
	-rm -rf $(DESTDIR)$(SHAREDIR)
