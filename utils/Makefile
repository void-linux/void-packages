PREFIX  ?= /usr/local
CFLAGS += -Wall -Werror -O3 -I$(PREFIX)/include
CFLAGS += -funroll-all-loops -ftree-loop-linear
LDFLAGS += -lprop

all: xbps_digest xbps_pkgdb xbps-cmpver clean_objs
 
xbps-cmpver: xbps-cmpver.o
	$(CC) $(CFLAGS) $< -o $@

sha256_digest: sha256_digest.o
	$(CC) $(CFLAGS) -c $@

xbps-digest: xbps-digest.o
	$(CC) $(CFLAGS) -c $@

xbps_digest: xbps-digest.o sha256_digest.o
	$(CC) $(LDFLAGS) -o xbps-digest xbps-digest.o sha256_digest.o

xbps-pkgdb:
	$(CC) $(CFLAGS) -c $@

plist_utils:
	$(CC) $(CFLAGS) -c $@

xbps_pkgdb: xbps-pkgdb.o plist_utils.o
	$(CC) $(LDFLAGS) -o xbps-pkgdb xbps-pkgdb.o plist_utils.o

clean_objs:
	-rm -f *.o

clean: clean_objs
	-rm -f xbps-digest xbps-pkgdb xbps-cmpver
