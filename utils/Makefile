CFLAGS += -Wall -Werror -O3 -funroll-all-loops -ftree-loop-linear

all: xbps-digest
 
xbps-digest: xbps-digest.o
	$(CC) $(CFLAGS) $< -o $@

clean:
	-rm -rf *.o xbps-digest

