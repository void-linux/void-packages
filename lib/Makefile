include ../vars.mk

# The shared library.
MAJOR		= 0
MINOR		= 0
MICRO		= 0
LIBXBPS_SO	= $(LIBXBPS).$(MAJOR).$(MINOR).$(MICRO)
LIBXBPS		= libxbps.so
LIBXBPS_LDFLAGS	= -larchive -lprop -shared -Wl,-soname,$(LIBXBPS).$(MAJOR)

OBJECTS	=	cmpver.o depends.o humanize_number.o install.o plist.o
OBJECTS	+=	sha256.o util.o repository.o fexec.o remove.o unpack.o

all: $(LIBXBPS)
.PHONY: all

$(LIBXBPS): $(OBJECTS)
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
