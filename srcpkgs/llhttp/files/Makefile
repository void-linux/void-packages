# Makefile template for shared library

CC ?= gcc 
override CFLAGS += -fPIC -Wall -Wextra -O2 -DNDEBUG -Iinclude
override LDFLAGS += -shared -Wl,-soname,libllhttp.so.1
RM = rm -f 
TARGET_LIB = libllhttp.so.1.0

SRCS = src/api.c src/http.c src/llhttp.c
OBJS = $(SRCS:.c=.o)

.PHONY: all
all: ${TARGET_LIB}

$(TARGET_LIB): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

$(SRCS:.c=.d):%.d:%.c
	$(CC) $(CFLAGS) -MM $< >$@

include $(SRCS:.c=.d)

.PHONY: clean
clean:
	-${RM} ${TARGET_LIB} ${OBJS} $(SRCS:.c=.d)
