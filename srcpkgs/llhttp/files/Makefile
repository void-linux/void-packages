AR ?= ar
RANLIB ?= ranlib
OUTPUTFILE  = libllhttp.a
INCLUDES = -Iinclude/
override CFLAGS := $(CFLAGS) $(INCLUDES)
# Default target
.PHONY: all
all: $(OUTPUTFILE)

$(OUTPUTFILE): src/api.o src/http.o src/llhttp.o
	$(AR) ru $@ $^
	$(RANLIB) $@
