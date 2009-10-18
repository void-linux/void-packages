# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(DESTDIR)$(PREFIX)/sbin
#
# The following two vars shouldn't be specified with DESTDIR!
#
SHAREDIR ?= $(PREFIX)/share/xbps-src/shutils
ETCDIR	?= $(PREFIX)/etc
