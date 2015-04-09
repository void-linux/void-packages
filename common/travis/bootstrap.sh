#! /bin/sh
#
# bootstrap.sh

mkdir -p hostdir/repocache 
if [ -d $HOME/repocache ]; then
	ln $HOME/repocache/* hostdir/repocache;
else
	mkdir -p $HOME/repocache
fi

./xbps-src binary-bootstrap
