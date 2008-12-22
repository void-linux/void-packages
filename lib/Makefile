include ../vars.mk

# The shared library.
MAJOR		= 0
MINOR		= 0
MICRO		= 0
LIBXBPS_SO	= $(LIBXBPS).$(MAJOR).$(MINOR).$(MICRO)
LIBXBPS		= libxbps.so
LIBXBPS_LDFLAGS	= -lprop -shared -Wl,-soname,$(LIBXBPS).$(MAJOR)

all: $(LIBXBPS)
.PHONY: all

$(LIBXBPS): sha256.o plist.o
	$(CC) $(LIBXBPS_LDFLAGS) $^ -o $(LIBXBPS_SO)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS).$(MAJOR)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS)

install: $(LIBXBPS)
	install -d $(LIBDIR)
	install -m 644 $(LIBXBPS_SO) $(LIBDIR)

.PHONY: clean
clean: clean-lib clean-objs

clean-lib:
	-rm -f $(LIBXBPS)*

clean-objs:
	-rm -f *.o
