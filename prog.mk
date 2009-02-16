include $(TOPDIR)/vars.mk

OBJS ?=	main.o

all: $(BIN)
.PHONY: all

$(BIN): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

.PHONY: clean
clean: clean-bins clean-objs

clean-bins:
	-rm -f $(BIN)

clean-objs:
	-rm -f $(OBJS)

install: $(BIN)
	install -d $(SBINDIR)
	install $(INSTALL_STRIPPED) -m 755 $(BIN) $(SBINDIR)
