# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(DESTDIR)$(PREFIX)/sbin
#
# The following vars shouldn't be specified with DESTDIR!
#
SHAREDIR ?= $(PREFIX)/share/xbps-src
LIBEXECDIR ?= $(PREFIX)/libexec
ETCDIR	?= $(PREFIX)/etc
