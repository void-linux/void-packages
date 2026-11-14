LINK.o=$(LINK.cc)

all: redo cubehash.1 redo-ifchange.1 redo-ifcreate.1 redo.1

redo: redo.o popt-bool-string.o popt-bool.o popt-compound-1arg.o popt-compound-2arg.o popt-integral.o popt-named.o popt-signed.o popt-simple.o popt-string-list.o popt-string-pair-list.o popt-string-pair.o popt-string.o popt-table.o popt-top-table.o popt-unsigned.o popt.o jobserver.o FileDescriptorOwner.o lockfile.o tai64.o tai64n.o main.o ErrorReporter.o ECMA48Output.o TerminalColours.o ProcessEnvironment.o TerminalCapabilities.o DefaultEnvironment.o wait.o

redo.cpp: version.h

wait.cpp: wait.cpp.waitid
	cp $< $@

version.h:
	printf '#define VERSION "'$(VERSION)'"\n' >$@

version.xml:
	printf '<refmiscinfo class="version">'$(VERSION)'</refmiscinfo>' >$@

%.1: %.xml version.xml
	xmlto --skip-validation -o . man $<
