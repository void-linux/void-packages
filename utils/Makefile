PREFIX  ?= /usr/local
CFLAGS += -Wall -Werror -O3 -I$(PREFIX)/include
CFLAGS += -funroll-all-loops -ftree-loop-linear
LDFLAGS += -lprop

all: xbps_digest xbps_pkgdb xbps_bin xbps-cmpver clean_objs
 
xbps-cmpver: xbps-cmpver.o
	$(CC) $(CFLAGS) $< -o $@

sha256: sha256.o
	$(CC) $(CFLAGS) -c $@

xbps-digest: xbps-digest.o
	$(CC) $(CFLAGS) -c $@

xbps_digest: xbps-digest.o sha256.o
	$(CC) -o xbps-digest xbps-digest.o sha256.o

xbps-pkgdb:
	$(CC) $(CFLAGS) -c $@

plist:
	$(CC) $(CFLAGS) -c $@

xbps_pkgdb: xbps-pkgdb.o plist.o
	$(CC) $(LDFLAGS) -o xbps-pkgdb xbps-pkgdb.o plist.o

xbps-bin:
	$(CC) $(CFLAGS) -c $@

xbps_bin: xbps-bin.o plist.o
	$(CC) $(LDFLAGS) -o xbps-bin xbps-bin.o plist.o

clean_objs:
	-rm -f *.o

clean: clean_objs
	-rm -f xbps-digest xbps-pkgdb xbps-cmpver
