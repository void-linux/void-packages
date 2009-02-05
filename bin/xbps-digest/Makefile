TOPDIR = ../..
include $(TOPDIR)/vars.mk

EXTRA_CFLAGS = -funroll-all-loops -ftree-loop-linear
OBJS = main.o
BIN = xbps-digest

all: $(BIN)
.PHONY: all

$(BIN): $(OBJS)
	$(CC) $(EXTRA_CFLAGS) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean: clean-bins clean-objs

clean-bins:
	-rm -f $(BIN)

clean-objs:
	-rm -f *.o

install: $(BIN)
	install -d $(SBINDIR)
	install -m 755 $(BIN) $(SBINDIR)
