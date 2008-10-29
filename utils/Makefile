CFLAGS += -Wall -Werror -O3 -funroll-all-loops -ftree-loop-linear
PREFIX  ?= /usr/local
PKGDB_CFLAGS  += -Wall -Werror -I$(PREFIX)/include
PKGDB_LDFLAGS += -lprop

all: xbps-digest xbps-pkgdb xbps-cmpver clean_objs
 
xbps-cmpver: xbps-cmpver.o
	$(CC) $(CFLAGS) $< -o $@

xbps-digest: xbps-digest.o
	$(CC) $(CFLAGS) $< -o $@

xbps-pkgdb: xbps-pkgdb.o
	$(CC) $(PKGDB_CFLAGS) $(CFLAGS) $(PKGDB_LDFLAGS) $< -o $@

clean_objs:
	-rm -f *.o

clean: clean_objs
	-rm -f xbps-digest xbps-pkgdb xbps-cmpver
