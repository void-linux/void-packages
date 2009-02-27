# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(PREFIX)/sbin
LIBDIR	?= $(PREFIX)/lib
ETCDIR	?= $(PREFIX)/etc
TOPDIR	?= ..
INSTALL_STRIPPED ?= -s

LDFLAGS += -L$(TOPDIR)/lib -L$(PREFIX)/lib -lxbps
CPPFLAGS += -I$(TOPDIR)/include
CFLAGS += -O2 -Wall -Wextra -Werror -fPIC -DPIC
