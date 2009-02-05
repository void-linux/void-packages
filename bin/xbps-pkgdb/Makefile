TOPDIR = ../..
include $(TOPDIR)/vars.mk

OBJS = main.o
BIN = xbps-pkgdb

all: $(BIN)
.PHONY: all

$(BIN): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean: clean-bins clean-objs

clean-bins:
	-rm -f $(BIN)

clean-objs:
	-rm -f *.o

install: $(BIN)
	install -d $(SBINDIR)
	install -m 755 $(BIN) $(SBINDIR)
