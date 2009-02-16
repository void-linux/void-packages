include ../vars.mk

# The shared library.
MAJOR		= 0
MINOR		= 0
MICRO		= 0
LIBXBPS_SO	= $(LIBXBPS).$(MAJOR).$(MINOR).$(MICRO)
LIBXBPS		= libxbps.so
LIBXBPS_LDFLAGS	= -larchive -lprop -shared -Wl,-soname,$(LIBXBPS).$(MAJOR)

OBJECTS	=	cmpver.o depends.o fexec.o humanize_number.o install.o
OBJECTS	+=	plist.o remove.o repository.o requiredby.o sha256.o
OBJECTS	+=	sortdeps.o unpack.o util.o

all: $(LIBXBPS)
.PHONY: all

$(LIBXBPS): $(OBJECTS)
	$(CC) $(LIBXBPS_LDFLAGS) $^ -o $(LIBXBPS_SO)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS).$(MAJOR)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS)

install: $(LIBXBPS)
	install -d $(LIBDIR)
	install -m 644 $(LIBXBPS_SO) $(LIBDIR)
	cp -a $(LIBXBPS) $(LIBDIR)
	cp -a $(LIBXBPS).$(MAJOR) $(LIBDIR)

.PHONY: clean
clean: clean-lib clean-objs

clean-lib:
	-rm -f $(LIBXBPS)*

clean-objs:
	-rm -f *.o
