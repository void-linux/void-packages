PREFIX  ?= /usr/local
BINDIR	?= $(PREFIX)/bin
CFLAGS	+= -Wall -Werror -O3 -I$(PREFIX)/include
CFLAGS	+= -funroll-all-loops -ftree-loop-linear -fPIC -DPIC
LDFLAGS	+= -L $$(pwd) -Wl,-rpath $$(pwd) -lxbps
BINS	?= xbps-bin xbps-cmpver xbps-digest xbps-pkgdb

# The shared library.
MAJOR		= 0
MINOR		= 0
MICRO		= 0
LIBXBPS_SO	= $(LIBXBPS).$(MAJOR).$(MINOR).$(MICRO)
LIBXBPS		= libxbps.so
LIBXBPS_LDFLAGS	= -lprop -shared -Wl,-soname,$(LIBXBPS).$(MAJOR)

all: $(LIBXBPS) $(BINS)
.PHONY: all

$(LIBXBPS): sha256.o plist.o
	$(CC) $(LIBXBPS_LDFLAGS) $^ -o $(LIBXBPS_SO)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS).$(MAJOR)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS)

xbps-bin: xbps-bin.o
	$(CC) $(LDFLAGS) $^ -o $@

xbps-cmpver: xbps-cmpver.o
	$(CC) $^ -o $@

xbps-digest: xbps-digest.o
	$(CC) $(LDFLAGS) $^ -o $@

xbps-pkgdb: xbps-pkgdb.o
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean: clean-bins clean-objs

clean-bins:
	-rm -f $(BINS) $(LIBXBPS)*

clean-objs:
	-rm -f *.o $(LIBXBPS)*

install: $(BINS)
	install -D $(BINS) $(BINDIR)
