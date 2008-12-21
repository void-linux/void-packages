# Common variables.

PREFIX	?= /usr/local
BINDIR	?= $(PREFIX)/bin
LIBDIR	?= $(PREFIX)/lib

CPPFLAGS += -I../include
CFLAGS += -O2 -Wall -Werror -fPIC -DPIC
