all:
	mkdir -p utils
	cd xbps-digest && make
	cp -f xbps-digest/xbps-digest utils/
	cd xbps-pkgdb && make
	cp -f xbps-pkgdb/xbps-pkgdb utils/
	cd xbps-digest && make clean
	cd xbps-pkgdb && make clean
