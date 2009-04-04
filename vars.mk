# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(PREFIX)/sbin
LIBDIR	?= $(PREFIX)/lib
ETCDIR	?= $(PREFIX)/etc
TOPDIR	?= ..
INSTALL_STRIPPED ?= -s

LDFLAGS += -L$(TOPDIR)/lib -L$(PREFIX)/lib -lxbps
CPPFLAGS += -I$(TOPDIR)/include -D_BSD_SOURCE -D_XOPEN_SOURCE=600
CPPFLAGS += -D_GNU_SOURCE
WARNFLAGS ?= -pedantic -std=c99 -Wall -Wextra -Werror -Wshadow -Wformat=2
WARNFLAGS += -Wmissing-declarations -Wcomment -Wunused-macros -Wendif-labels
CFLAGS += $(WARNFLAGS) -O2 -fPIC -DPIC
