PREFIX	?= /usr/local
BINDIR	?= $(PREFIX)/bin

all:
	cd utils && make

install:
	install -D xbps-src.sh $(BINDIR)/xbps-src
	cd utils && make install

uninstall:
	-rm -f $(BINDIR)/xbps-*

clean:
	cd utils && make clean
