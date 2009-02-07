# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(PREFIX)/sbin
LIBDIR	?= $(PREFIX)/lib
ETCDIR	?= $(PREFIX)/etc
TOPDIR	?= ..

LDFLAGS += -L$(TOPDIR)/lib -L$(PREFIX)/lib -lxbps
CPPFLAGS += -I$(TOPDIR)/include
CFLAGS += -Wstack-protector -fstack-protector-all
CFLAGS += -O2 -Wall -Werror -fPIC -DPIC
