TARGET = interbench
LIBS = -lm -pthread -lrt
CC ?= gcc
CFLAGS ?= -g -Wall

.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = $(patsubst %.c, %.o, $(wildcard *.c))
HEADERS = $(wildcard *.h)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -Wall $(LIBS) $(LDFLAGS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)

install:
	install -Dm755 $(TARGET) $(DESTDIR)/usr/bin/$(TARGET)
	install -Dm644 $(TARGET).8 $(DESTDIR)/usr/share/man/man8/$(TARGET).8
	install -Dm644 readme $(DESTDIR)/usr/share/doc/$(TARGET)/readme
	install -Dm644 readme.interactivity $(DESTDIR)/usr/share/doc/$(TARGET)/readme.interactivity
