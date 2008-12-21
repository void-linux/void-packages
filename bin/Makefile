include ../vars.mk

EXTRA_CFLAGS = -funroll-all-loops -ftree-loop-linear
LDFLAGS	+= -L../lib -Wl,-rpath $$(pwd)/../lib -lxbps

BINS = xbps-bin xbps-cmpver xbps-digest xbps-pkgdb

all: $(BINS)
.PHONY: all

xbps-bin: xbps-bin.o
	$(CC) $(LDFLAGS) $^ -o $@

xbps-cmpver: xbps-cmpver.o
	$(CC) $^ -o $@

xbps-digest: xbps-digest.o
	$(CC) $(EXTRA_CFLAGS) $(LDFLAGS) $^ -o $@

xbps-pkgdb: xbps-pkgdb.o
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean: clean-bins clean-objs

clean-bins:
	-rm -f $(BINS)

clean-objs:
	-rm -f *.o

install: $(BINS)
	install -D $(BINS)
