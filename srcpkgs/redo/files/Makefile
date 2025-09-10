LINK.o=$(LINK.cc)

all: redo cubehash.1 redo-ifchange.1 redo-ifcreate.1 redo.1

redo: redo.o popt-bool-string.o popt-bool.o popt-compound-2arg.o popt-compound.o popt-integral.o popt-named.o popt-signed.o popt-simple.o popt-string-list.o popt-string-pair-list.o popt-string-pair.o popt-string.o popt-table.o popt-top-table.o popt-unsigned.o popt.o jobserver.o FileDescriptorOwner.o wait.o lockfile.o

redo.cpp: version.h

version.h:
	printf '#define VERSION "'$(VERSION)'"\n' >$@

%.1: %.pod
	pod2man --center "redo package" --release "v$(VERSION)" $< >$@
