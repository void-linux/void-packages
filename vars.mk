# Common variables.

PREFIX	?= /usr/local
SBINDIR	?= $(PREFIX)/sbin
LIBDIR	?= $(PREFIX)/lib

CPPFLAGS += -I../include
CFLAGS += -Wstack-protector -fstack-protector-all
CFLAGS += -O2 -Wall -Werror -fPIC -DPIC
