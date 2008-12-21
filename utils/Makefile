PREFIX  ?= /usr/local
BINDIR	?= $(PREFIX)/bin
CFLAGS	+= -Wall -Werror -O3 -I$(PREFIX)/include
CFLAGS	+= -funroll-all-loops -ftree-loop-linear
LDFLAGS	+= -lprop
BINS	?= xbps-bin xbps-cmpver xbps-digest xbps-pkgdb

all: $(BINS) clean-objs
.PHONY: all

xbps-cmpver.o: xbps_api.h
sha256.o: xbps_api.h sha256.h
xbps-digest.o: xbps_api.h sha256.h
xbps-pkgdb.o: xbps_api.h plist.h
plist.o: xbps_api.h plist.h
xbps-bin.o: xbps_api.h plist.h

xbps-bin: xbps-bin.o plist.o
	$(CC) $(LDFLAGS) -o xbps-bin xbps-bin.o plist.o

xbps-cmpver: xbps-cmpver.o
	$(CC) -o xbps-cmpver xbps-cmpver.o

xbps-digest: xbps-digest.o sha256.o
	$(CC) -o xbps-digest xbps-digest.o sha256.o

xbps-pkgdb: xbps-pkgdb.o plist.o
	$(CC) $(LDFLAGS) -o xbps-pkgdb xbps-pkgdb.o plist.o

.PHONY: clean
clean: clean-bins clean-objs

clean-bins:
	-rm -f $(BINS)

clean-objs:
	-rm -f *.o

install: $(BINS)
	install -D $(BINS) $(BINDIR)
