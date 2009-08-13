include ../vars.mk

# The shared library.
MAJOR		= 0
MINOR		= 0
MICRO		= 0
LIBXBPS_SO	= $(LIBXBPS).$(MAJOR).$(MINOR).$(MICRO)
LIBXBPS		= libxbps.so
LIBXBPS_STATIC 	= libxbps.a
LIBXBPS_LDFLAGS	= -larchive -lprop -shared -Wl,-soname,$(LIBXBPS).$(MAJOR)

OBJECTS	=	configure.o cmpver.o depends.o fexec.o findpkg.o
OBJECTS	+=	humanize_number.o orphans.o plist.o purge.o register.o remove.o
OBJECTS	+=	repository.o requiredby.o sha256.o sortdeps.o state.o unpack.o
OBJECTS	+=	util.o

all: $(LIBXBPS) $(LIBXBPS_STATIC)
.PHONY: all

$(LIBXBPS): $(OBJECTS)
	$(CC) $(LIBXBPS_LDFLAGS) $^ -o $(LIBXBPS_SO)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS).$(MAJOR)
	-ln -sf $(LIBXBPS_SO) $(LIBXBPS)

$(LIBXBPS_STATIC): $(OBJECTS)
	$(AR) rcs $@ $^
	ranlib $@

install: $(LIBXBPS) $(LIBXBPS_STATIC)
	install -d $(LIBDIR)
	install -m 644 $(LIBXBPS_STATIC) $(LIBDIR)
	install -m 644 $(LIBXBPS_SO) $(LIBDIR)
	cp -a $(LIBXBPS) $(LIBDIR)
	cp -a $(LIBXBPS).$(MAJOR) $(LIBDIR)

.PHONY: clean
clean: clean-lib clean-objs

clean-lib:
	-rm -f $(LIBXBPS)*
	-rm -f $(LIBXBPS_STATIC)

clean-objs:
	-rm -f *.o
