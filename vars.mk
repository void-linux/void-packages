# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(PREFIX)/sbin
LIBDIR	?= $(PREFIX)/lib

CPPFLAGS += -I../include
CFLAGS += -O2 -Wall -Werror -fPIC -DPIC
