VERSION?=	0.2B
DESTDIR?=	/
PREFIX=		$(DESTDIR)/usr
LIBDIR=		$(PREFIX)/lib
INCDIR=		$(PREFIX)/include

SILENT?=
SOURCES=	icu.c icu.collator.c icu.idna.c icu.normalizer.c icu.regex.c \
		icu.stringprep.c icu.ufile.c icu.ustring.c icu.utf8.c matchengine.c
OBJS=		icu.o icu.collator.o icu.idna.o icu.normalizer.o icu.regex.o \
		icu.stringprep.o icu.ufile.o icu.ustring.o icu.utf8.o matchengine.o
HEADERS=	formatting.h icu4lua.h matchengine.h
TARGET=		libicu4lua.so
SO_MAJOR=	0
SO_MINOR=	1
SO_BUILD=	1
SO_VER=		$(SO_MAJOR).$(SO_MINOR).$(SO_BUILD)
ICU_CFLAGS=	`pkg-config --cflags icu-i18n icu-io`
ICU_LIBS=	`pkg-config --libs icu-i18n icu-io`
LUA_CFLAGS=	`pkg-config --cflags lua5.1`
LUA_LIBS=	`pkg-config --libs lua5.1`

all:	$(TARGET)

$(TARGET):	$(OBJS)
	@echo "Linking $@ ..."
	$(SILENT)$(CC) -shared -Wl,-soname,$(TARGET).$(SO_MAJOR) \
		-o $(TARGET).$(SO_VER) $(LDFLAGS) \
		$(OBJS) $(LIBS) $(LUA_LIBS) -L/usr/lib/icu $(ICU_LIBS)

.c.o:
	@echo "Compling $< ..."
	$(SILENT)$(CC) $(CFLAGS) $(ICU_CFLAGS) $(LUA_CFLAGS) -o $@ -c $<

install:	$(TARGET)
	@echo "Installing..."
	install -d $(LIBDIR)/
	install -m 0755 $(TARGET).$(SO_VER) $(LIBDIR)
	ln -s $(TARGET).$(SO_VER) $(LIBDIR)/$(TARGET).$(SO_MAJOR).$(SO_MINOR)
	ln -s $(TARGET).$(SO_MAJOR).$(SO_MINOR) $(LIBDIR)/$(TARGET).$(SO_MAJOR)
	ln -s $(TARGET).$(SO_MAJOR) $(LIBDIR)/$(TARGET)
	install -d $(INCDIR)/icu4lua
	install -m 0644 *.h $(INCDIR)/icu4lua
	install -d $(LIBDIR)/pkgconfig
	sed < icu4lua.pc.in -e "s;@VERSION@;$(VERSION);" \
		> $(LIBDIR)/pkgconfig/icu4lua.pc

