# install locations
PREFIX = /usr/
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
SRCDIR = $(PREFIX)/src
STDLIB = $(SRCDIR)/hare/stdlib
LIBEXECDIR = $(PREFIX)/libexec
TOOLDIR = $(LIBEXECDIR)/hare

# variables used during build
PLATFORM = linux
ARCH = @CARCH@
HAREFLAGS =
HARECFLAGS =
QBEFLAGS =
ASFLAGS =
LDLINKFLAGS = --gc-sections -z noexecstack

# commands used by the build script
HAREC = harec
QBE = qbe
AS = as
LD = ld
SCDOC = scdoc

# build locations
HARECACHE = .cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION = @VERSION@

# For cross-compilation, modify the variables below
LIBC = @LIBC@
AARCH64_AS=aarch64-linux-$(LIBC)-as
AARCH64_CC=aarch64-linux-$(LIBC)-gcc
AARCH64_LD=aarch64-linux-$(LIBC)-ld

RISCV64_AS=riscv64-linux-$(LIBC)-as
RISCV64_CC=riscv64-linux-$(LIBC)-gcc
RISCV64_LD=riscv64-linux-$(LIBC)-ld

X86_64_AS=x86_64-linux-$(LIBC)-as
X86_64_CC=x86_64-linux-$(LIBC)-gcc
X86_64_LD=x86_64-linux-$(LIBC)-ld
