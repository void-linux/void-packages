# Override PREFIX to look in correct path.
#
PREFIX	?= /usr/local
CFLAGS	+= -Wall -Werror -I$(PREFIX)/include
LDFLAGS	+= -lprop

all: xbps-pkgdb

xbps-pkgdb: xbps-pkgdb.o
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o $@

clean:
	-rm -f *.o *.core xbps-pkgdb
