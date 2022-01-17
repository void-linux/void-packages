/*
 * iconv.c
 * Implementation of SUSv4 XCU iconv utility
 * Copyright © 2011 Rich Felker
 * Licensed under the terms of the GNU General Public License, v2 or later
 */

#include <stdlib.h>
#include <stdio.h>
#include <iconv.h>
#include <locale.h>
#include <langinfo.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int main(int argc, char **argv)
{
	const char *from=0, *to=0;
	int b;
	iconv_t cd;
	char buf[BUFSIZ];
	char outbuf[BUFSIZ*4];
	char *in, *out;
	size_t inb;
	size_t l;
	size_t unitsize=0;
	int err=0;
	FILE *f;

	while ((b = getopt(argc, argv, "f:t:csl")) != EOF) switch(b) {
	case 'l':
		puts("UTF-8, UTF-16BE, UTF-16LE, UTF-32BE, UTF32-LE, UCS-2BE, UCS-2LE, WCHAR_T,\n"
			"US_ASCII, ISO8859-1, ISO8859-2, ISO8859-3, ISO8859-4, ISO8859-5,\n"
			"ISO8859-6, ISO8859-7, ...");
		exit(0);
	case 'c': case 's': break;
	case 'f': from=optarg; break;
	case 't': to=optarg; break;
	default: exit(1);
	}

	if (!from || !to) {
		setlocale(LC_CTYPE, "");
		if (!to) to = nl_langinfo(CODESET);
		if (!from) from = nl_langinfo(CODESET);
	}
	cd = iconv_open(to, from);
	if (cd == (iconv_t)-1) {
		if (iconv_open(to, "WCHAR_T") == (iconv_t)-1)
			fprintf(stderr, "iconv: destination charset %s: ", to);
		else
			fprintf(stderr, "iconv: source charset %s: ", from);
		perror("");
		exit(1);
	}
	if (optind == argc) argv[argc++] = "-";

	for (; optind < argc; optind++) {
		if (argv[optind][0]=='-' && !argv[optind][1]) {
			f = stdin;
			argv[optind] = "(stdin)";
		} else if (!(f = fopen(argv[optind], "rb"))) {
			fprintf(stderr, "iconv: %s: ", argv[optind]);
			perror("");
			err = 1;
			continue;
		}
		inb = 0;
		for (;;) {
			in = buf;
			out = outbuf;
			l = fread(buf+inb, 1, sizeof(buf)-inb, f);
			inb += l;
			if (!inb) break;
			if (iconv(cd, &in, &inb, &out, (size_t [1]){sizeof outbuf})==-1
			 && errno == EILSEQ) {
				if (!unitsize) {
					wchar_t wc='0';
					char dummy[4], *dummyp=dummy;
					iconv_t cd2 = iconv_open(from, "WCHAR_T");
					if (cd == (iconv_t)-1) {
						unitsize = 1;
					} else {
						iconv(cd2,
							(char *[1]){(char *)&wc},
							(size_t[1]){1},
							&dummyp, (size_t[1]){4});
						unitsize = dummyp-dummy;
						if (!unitsize) unitsize=1;
					}
				}
				inb-=unitsize;
				in+=unitsize;
			}
			if (inb && !l && errno==EINVAL) break;
			if (out>outbuf && !fwrite(outbuf, out-outbuf, 1, stdout)) {
				perror("iconv: write error");
				exit(1);
			}
			if (inb) memmove(buf, in, inb);
		}
		if (ferror(f)) {
			fprintf(stderr, "iconv: %s: ", argv[optind]);
			perror("");
			err = 1;
		}
	}
	return err;
}
