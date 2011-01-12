prefix = /usr
DESTDIR =
DEBUG = false
FETCH_WITH_INET6 = true
FETCH_WITH_OPENSSL = true

WARNINGS = -Wall -Wstrict-prototypes -Wsign-compare -Wchar-subscripts \
           -Wpointer-arith -Wcast-align

CFLAGS  ?= -O2 -pipe

CFLAGS  += -fPIC $(WARNINGS)
CFLAGS  += -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGE_FILES
CFLAGS  += -DFTP_COMBINE_CWDS -DNETBSD

ifeq ($(strip $(FETCH_WITH_INET6)), true)
CFLAGS  += -DINET6
endif

ifeq ($(strip $(FETCH_WITH_OPENSSL)), true)
CFLAGS  += -DWITH_SSL
LDADD   += -Wl,-lssl -Wl,-lcrypto
endif

INSTALL = install -c -D

OBJS= fetch.o common.o ftp.o http.o file.o
INCS= fetch.h common.h
GEN = ftperr.h httperr.h
MAN = libdownload.3

all: libfetch.so libfetch.a
.PHONY: all

%.o: %.c $(INCS) $(GEN)
	$(CC) $(CFLAGS) -c $<

ftperr.h: ftp.errors Makefile errlist.sh
	./errlist.sh ftp_errlist FTP ftp.errors > $@

httperr.h: http.errors Makefile errlist.sh
	./errlist.sh http_errlist HTTP http.errors > $@

libfetch.so: $(GEN) $(INCS) $(OBJS)
	rm -f $@
	$(CC) $(LDFLAGS) $(OBJS) $(LDADD) -shared -fPIC -o $@

libfetch.a: $(GEN) $(INCS) $(OBJS)
	rm -f $@
	$(AR) rcs $@ $(OBJS)

clean:
	rm -f libfetch.so libfetch.a *.o $(GEN)
.PHONY: clean

install: all
	$(INSTALL) -m 755 libfetch.so $(DESTDIR)$(prefix)/lib/libfetch.so
	$(INSTALL) -m 644 libfetch.a $(DESTDIR)$(prefix)/lib/libfetch.a
	$(INSTALL) -m 644 fetch.h $(DESTDIR)$(prefix)/include/fetch.h
	$(INSTALL) -m 644 fetch.3 $(DESTDIR)$(prefix)/share/man/man3/fetch.3
.PHONY: install

uninstall:
	rm -f $(DESTDIR)$(prefix)/lib/libfetch.so
	rm -f $(DESTDIR)$(prefix)/lib/libfetch.a
	rm -f $(DESTDIR)$(prefix)/include/fetch.h
	rm -f $(DESTDIR)$(prefix)/share/man/man3/fetch.3
.PHONY: uninstall
