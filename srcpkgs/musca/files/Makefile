CFLAGS?=-Wall -g
LDFLAGS?=-s
LIBS?=-L/usr/lib -lX11 -lm

all:	musca apis xlisten

musca:	musca.o
	$(CC) $(LDFLAGS) -o $@ $< $(LIBS)

apis:	apis.o
	$(CC) $(LDFLAGS) -o $@ $< $(LIBS)

xlisten:	xlisten.o
	$(CC) $(LDFLAGS) -o $@ $< $(LIBS)

%.o:	%.c
	$(CC) $(CFLAGS) -o $@ -c $<

clean:
	rm -f musca apis
