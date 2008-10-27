CFLAGS += -Wall -Werror -O3 -funroll-all-loops -ftree-loop-linear
PREFIX  ?= /usr/local
PKGDB_CFLAGS  += -Wall -Werror -I$(PREFIX)/include
PKGDB_LDFLAGS += -lprop

all: xbps-digest xbps-pkgdb
 
xbps-digest: xbps-digest.o
	$(CC) $(CFLAGS) $< -o $@

xbps-pkgdb: xbps-pkgdb.o
	$(CC) $(PKGDB_CFLAGS) $(CFLAGS) $(PKGDB_LDFLAGS) $< -o $@

clean:
	-rm -rf *.o xbps-digest xbps-pkgdb

